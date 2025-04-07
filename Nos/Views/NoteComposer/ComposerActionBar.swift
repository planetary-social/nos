import Dependencies
import Foundation
import SwiftUI
import SwiftUINavigation

/// A horizontal bar that gives the user options to customize their message in the message composer.
struct ComposerActionBar: View {

    /// A controller for the text entered in the note composer.
    @Binding var editingController: NoteEditorController

    /// The expiration time for the note, if any.
    @Binding var expirationTime: TimeInterval?

    /// Whether we're currently uploading an image or not.
    @Binding var isUploadingImage: Bool

    /// Turns on and off a Preview switch.
    @Binding var showPreview: Bool
    
    /// The kind of post to create (text, picture, video, etc.)
    @Binding var postKind: PostKind

    @Dependency(\.fileStorageAPIClient) private var fileStorageAPIClient

    private enum SubMenu {
        case expirationDate
        case postKind
    }

    @State private var subMenu: SubMenu?
    @State private var alert: AlertState<AlertAction>?

    fileprivate enum AlertAction {
        case cancel
        case getAccount
    }

    private var backArrow: some View {
        Button {
            subMenu = .none
        } label: {
            Image.backChevron
                .frame(minWidth: 44, minHeight: 44)
        }
        .transition(.opacity)
    }

    var body: some View {
        HStack(spacing: 0) {
            switch subMenu {
            case .none:
                defaultMenu
            case .expirationDate:
                backArrow
                ScrollView(.horizontal) {
                    HStack {
                        Text("noteDisappearsIn")
                            .font(.clarityRegular(.caption))
                            .foregroundColor(.secondaryTxt)
                            .transition(.move(edge: .trailing))
                            .padding(10)

                        ExpirationTimePicker(expirationTime: $expirationTime)
                            .padding(.vertical, 12)
                    }
                }
            case .postKind:
                backArrow
                ScrollView(.horizontal) {
                    HStack {
                        Text("postKind")
                            .font(.clarityRegular(.caption))
                            .foregroundColor(.secondaryTxt)
                            .transition(.move(edge: .trailing))
                            .padding(10)
                        
                        PostKindSelector(selectedKind: $postKind)
                            .padding(.vertical, 12)
                    }
                }
            }
            Spacer()
        }
        .frame(minHeight: 56)
        .animation(.easeInOut(duration: 0.2), value: subMenu)
        .transition(.move(edge: .leading))
        .onChange(of: expirationTime) { _, _ in
            subMenu = .none
        }
        .alert(unwrapping: $alert) { action in
            switch action {
            case .getAccount:
                if let url = URL(string: "https://nostr.build/plans/") {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            default:
                break
            }
        }
        .background(
            LinearGradient(
                colors: [Color.actionBarGradientTop, Color.actionBarGradientBottom],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(
            Rectangle()
                .frame(width: nil, height: 1, alignment: .top)
                .foregroundColor(Color.actionBarBorderTop),
            alignment: .top
        )
    }

    private var defaultMenu: some View {
        HStack(spacing: 0) {
            if !showPreview {
                attachMediaView
                expirationTimeView
                mentionButton
                postKindView
            }
            Spacer()
            previewToggle
        }
    }
    
    /// Post Kind Selector View
    private var postKindView: some View {
        Button {
            subMenu = .postKind
        } label: {
            Image(systemName: postKind.icon)
                .foregroundColor(.secondaryTxt)
                .frame(minWidth: 44, minHeight: 44)
        }
        .accessibilityLabel("postKind")
    }

    /// Attach Media View
    private var attachMediaView: some View {
        ImagePickerButton(cameraDevice: .rear, mediaTypes: [.image, .movie]) { imageURL in
            Task {
                await uploadImage(at: imageURL)
            }
        } label: {
            Image.attachMediaButton
                .foregroundColor(.secondaryTxt)
                .frame(minWidth: 44, minHeight: 44)
        }
        .padding(.leading, 8)
        .accessibilityLabel("attachMedia")
    }

    /// Expiration Time
    private var expirationTimeView: some View {
        Group {
            if let expirationTime, let option = ExpirationTimeOption(rawValue: expirationTime) {
                ExpirationTimeButton(
                    model: option,
                    showClearButton: true,
                    isSelected: Binding(get: {
                        self.expirationTime == option.timeInterval
                    }, set: {
                        self.expirationTime = $0 ? option.timeInterval : nil
                    })
                )
                .accessibilityLabel("expirationDate")
                .padding(12)
            } else {
                Button {
                    subMenu = .expirationDate
                } label: {
                    Image.disappearingMessages
                        .foregroundColor(.secondaryTxt)
                        .frame(minWidth: 44, minHeight: 44)
                }
            }
        }
    }

    /// Preview Toggle
    private var previewToggle: some View {
        Group {
            Text("preview")
                .padding(.horizontal, 10)
                .foregroundColor(Color.secondaryTxt)
            NosToggle(isOn: $showPreview)
                .labelsHidden()
                .disabled(editingController.isEmpty)
        }
    }

    /// Inserts a mention (`@`) symbol into the text editor.
    private var mentionButton: some View {
        Button {
            editingController.append(text: "@")
        } label: {
            Image.mention
                .foregroundColor(.secondaryTxt)
                .frame(minWidth: 44, minHeight: 44)
        }
    }

    /// Uploads an image at the given URL to a file storage service.
    /// - Parameter imageURL: File URL of the image the user wants to upload.
    private func uploadImage(
        at imageURL: URL
    ) async {
        do {
            startUploadingImage()
            let url = try await fileStorageAPIClient.upload(fileAt: imageURL, isProfilePhoto: false)
            await editingController.append(url)
            endUploadingImage()
        } catch {
            endUploadingImage()

            alert = createAlert(for: error)
        }
    }

    private func startUploadingImage() {
        self.isUploadingImage = true
    }
    
    private func endUploadingImage() {
        self.isUploadingImage = false
        self.subMenu = .none
    }

    /// Creates an alert based on the error
    private func createAlert(
        for error: Error
    ) -> AlertState<ComposerActionBar.AlertAction> {
        var title = String(localized: "errorUploadingFile", table: "ImagePicker")
        var message: String
        var buttons: [ButtonState<ComposerActionBar.AlertAction>] = [
            .default(
                TextState(String(localized: "ok")),
                action: .send(.cancel)
            )
        ]

        if case let FileStorageAPIClientError.fileTooBig(errorMessage) = error, let errorMessage {
            title = String(localized: "errorUploadingFileExceedsSizeLimit", table: "ImagePicker")
            message = String.localizedStringWithFormat(
                String(localized: "errorUploadingFileExceedsLimit", table: "ImagePicker"),
                errorMessage
            )
            buttons = [
                .cancel(
                    TextState(String(localized: "cancel")), action: .send(.cancel)
                ),
                .default(
                    TextState(String(localized: "getAccount", table: "ImagePicker")),
                    action: .send(.getAccount)
                )
            ]
        } else if case let FileStorageAPIClientError.uploadFailed(errorMessage) = error, let errorMessage {
            message = String.localizedStringWithFormat(
                String(localized: "errorUploadingFileWithMessage", table: "ImagePicker"),
                errorMessage
            )
        } else {
            message = String(localized: "errorUploadingFileMessage", table: "ImagePicker")
        }

        return AlertState(
            title: TextState(title),
            message: TextState(message),
            buttons: buttons
        )
    }
}

struct ComposerActionBar_Previews: PreviewProvider {
    
    @State static var controller = NoteEditorController()
    @State static var emptyExpirationTime: TimeInterval?
    @State static var setExpirationTime: TimeInterval? = 60 * 60
    @State static var showPreview = false
    @State static var postKind = PostKind.textNote
    
    static var previews: some View {
        VStack {
            Spacer()
            ComposerActionBar(
                editingController: $controller, 
                expirationTime: $emptyExpirationTime, 
                isUploadingImage: .constant(false),
                showPreview: $showPreview,
                postKind: $postKind
            )
            Spacer()
            ComposerActionBar(
                editingController: $controller, 
                expirationTime: $setExpirationTime, 
                isUploadingImage: .constant(false),
                showPreview: $showPreview,
                postKind: $postKind
            )
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.appBg)
        .environment(\.sizeCategory, .extraExtraLarge)
    }
}
