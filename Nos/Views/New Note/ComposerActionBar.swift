import Dependencies
import Foundation
import SwiftUI
import SwiftUINavigation

/// A horizontal bar that gives the user options to customize their message in the message composer.
struct ComposerActionBar: View {
    
    /// The expiration time for the note, if any.
    @Binding var expirationTime: TimeInterval?

    /// Whether we're currently uploading an image or not.
    @Binding var isUploadingImage: Bool

    /// The text in the note.
    @Binding var text: EditableNoteText

    @Dependency(\.fileStorageAPIClient) private var fileStorageAPIClient

    enum SubMenu {
        case expirationDate
    }
    
    @State private var subMenu: SubMenu?
    @State private var alert: AlertState<AlertAction>?
    
    fileprivate enum AlertAction {
    }
    
    var backArrow: some View {
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
                // Attach Media
                ImagePickerButton { imageURL in
                    Task {
                        do {
                            startUploadingImage()
                            let url = try await fileStorageAPIClient.upload(fileAt: imageURL)
                            text.append(url)
                            endUploadingImage()
                        } catch {
                            endUploadingImage()
                            print("error uploading: \(error)")
                            
                            alert = AlertState(title: {
                                TextState(String(localized: .imagePicker.errorUploadingFile))
                            }, message: {
                                if case let FileStorageAPIError.uploadFailed(message) = error {
                                    TextState(String(localized: .imagePicker.errorUploadingFileWithMessage(message)))
                                } else {
                                    TextState(String(localized: .imagePicker.errorUploadingFileMessage))
                                }
                            })
                        }
                    }
                } label: {
                    Image.attachMediaButton
                        .foregroundColor(.secondaryTxt)
                        .frame(minWidth: 44, minHeight: 44)
                }
                .padding(.leading, 8)
                .accessibilityLabel(Text(.localizable.attachMedia))
                
                // Expiration Time
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
                    .accessibilityLabel(Text(.localizable.expirationDate))
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
            case .expirationDate:
                backArrow
                ScrollView(.horizontal) {
                    HStack {
                        Text(.localizable.noteDisappearsIn)
                            .font(.clarity(.regular, textStyle: .caption1))
                            .foregroundColor(.secondaryTxt)
                            .transition(.move(edge: .trailing))
                            .padding(10)
                        
                        ExpirationTimePicker(expirationTime: $expirationTime)
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
        .alert(unwrapping: $alert) { (_: AlertAction?) in
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
    
    private func startUploadingImage() {
        self.isUploadingImage = true
    }
    
    private func endUploadingImage() {
        self.isUploadingImage = false
        self.subMenu = .none
    }
}

struct ComposerActionBar_Previews: PreviewProvider {
    
    @State static var emptyExpirationTime: TimeInterval?
    @State static var setExpirationTime: TimeInterval? = 60 * 60
    @State static var postText = EditableNoteText()
    
    static var previews: some View {
        VStack {
            Spacer()
            ComposerActionBar(expirationTime: $emptyExpirationTime, isUploadingImage: .constant(false), text: $postText)
            Spacer()
            ComposerActionBar(expirationTime: $setExpirationTime, isUploadingImage: .constant(false), text: $postText)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.appBg)
        .environment(\.sizeCategory, .extraExtraLarge)
    }
}
