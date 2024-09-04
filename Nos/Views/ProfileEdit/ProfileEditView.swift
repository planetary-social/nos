import Dependencies
import Logger
import PhotosUI
import SwiftUI
import SwiftUINavigation

struct EditProfileDestination: Hashable {
    let profile: Author
}

struct ProfileEditView: View {
    
    @EnvironmentObject private var router: Router
    @Environment(CurrentUser.self) private var currentUser
    @Environment(\.managedObjectContext) private var viewContext

    @Dependency(\.crashReporting) private var crashReporting

    @ObservedObject var author: Author
    
    @State private var nameText: String = ""
    @State private var bioText: String = ""
    @State private var avatarText: String = ""
    @State private var unsText: String = ""
    @State private var website: String = ""
    @State private var showNIP05Wizard = false
    @State private var showUniversalNameWizard = false
    @State private var unsController = UNSWizardController()
    @State private var showConfirmationDialog = false
    @State private var saveError: SaveError?
    
    @State private var isUploadingPhoto = false
    @State private var alert: AlertState<AlertAction>?
    
    fileprivate enum AlertAction {}

    private var showAlert: Binding<Bool> {
        Binding {
            saveError != nil
        } set: { _ in
            saveError = nil
        }
    }

    var body: some View {
        let avatarSize: CGFloat = 99
        
        NosForm {
            EditableAvatarView(
                size: avatarSize,
                urlString: $avatarText,
                isUploadingPhoto: $isUploadingPhoto
            )
            .padding(.top, 16)
            
            NosFormSection(label: .localizable.profilePicture) {
                NosTextField(label: .localizable.url, text: $avatarText)
                    #if os(iOS)
                    .keyboardType(.URL)
                    #endif
            }
            
            NosFormSection(label: .localizable.basicInfo) {
                NosTextField(label: .localizable.name, text: $nameText)
                FormSeparator()
                if author.hasNosNIP05 {
                    NosNIP05Field(
                        username: author.nosNIP05Username,
                        showConfirmationDialog: $showConfirmationDialog
                    )
                } else if let nip05 = author.nip05, !nip05.isEmpty {
                    NIP05Field(
                        nip05: nip05, 
                        showConfirmationDialog: $showConfirmationDialog
                    )
                } else {
                    NosNIP05Banner(
                        showNIP05Wizard: $showNIP05Wizard
                    )
                }
                FormSeparator()
                NosTextEditor(label: .localizable.bio, text: $bioText)
                    .frame(maxHeight: 200)
                FormSeparator()
                NosTextField(label: .localizable.website, text: $website)
            }
            
            HStack {
                Text(.localizable.identityVerification)
                    .font(.clarity(.semibold, textStyle: .headline))
                    .foregroundColor(.primaryTxt)
                    .padding(.top, 16)
                
                Spacer()
            }
            .padding(.horizontal, 13)
            
            if unsText.isEmpty {
                SetUpUNSBanner(
                    text: .localizable.unsTagline,
                    button: .localizable.manageUniversalName
                ) {
                    showUniversalNameWizard = true
                }
                .padding(13)
            } else {
                NosFormSection {
                    NosTextField(label: .localizable.universalName, text: $unsText)
                }
            }
        }
        .sheet(isPresented: $showUniversalNameWizard, content: {
            UNSWizard(controller: unsController, isPresented: $showUniversalNameWizard)
        })
        .sheet(isPresented: $showNIP05Wizard) {
            CreateUsernameWizard(isPresented: $showNIP05Wizard)
        }
        .sheet(isPresented: $showConfirmationDialog) {
            DeleteUsernameWizard(
                author: author,
                isPresented: $showConfirmationDialog
            )
        }
        .onChange(of: showUniversalNameWizard) { _, newValue in
            if !newValue {
                unsText = currentUser.author?.uns ?? ""
                unsController = UNSWizardController()
                author.willChangeValue(for: \Author.uns) // Trigger ProfileView to load USBC balance
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBg)
        .nosNavigationBar(title: .localizable.profileTitle)
        .navigationBarBackButtonHidden()
        .navigationBarItems(
            leading: Button(String(localized: .localizable.cancel), action: { 
                router.pop()
            }),
            trailing:
                ActionButton(title: .localizable.done) {
                    await save()
                }
                .disabled(isUploadingPhoto)
                .offset(y: -3)
        )
        .alert(isPresented: showAlert, error: saveError) {
            Button {
                saveError = nil
                Task {
                    await save()
                }
            } label: {
                Text(.localizable.retry)
            }
            Button {
                saveError = nil
            } label: {
                Text(.localizable.cancel)
            }
        }
        .id(author)
        .task {
            populateTextFields()
        }
    }

    private func populateTextFields() {
        viewContext.refresh(author, mergeChanges: true)
        nameText = author.name ?? author.displayName ?? ""
        bioText = author.about ?? ""
        avatarText = author.profilePhotoURL?.absoluteString ?? ""
        website = author.website ?? ""
        unsText = author.uns ?? ""
    }
    
    private func save() async {
        author.name = nameText
        author.about = bioText
        author.profilePhotoURL = URL(string: avatarText)
        author.website = website
        author.uns = unsText
        do {
            try viewContext.save()
            try await currentUser.publishMetadata()

            // Go back to profile page
            router.pop()
        } catch CurrentUserError.errorWhilePublishingToRelays {
            saveError = SaveError.unableToPublishChanges
        } catch {
            crashReporting.report(error)
            saveError = SaveError.unexpectedError
        }
    }

    enum SaveError: LocalizedError {
        case unexpectedError
        case unableToPublishChanges

        var errorDescription: String? {
            switch self {
            case .unexpectedError:
                return "Something unexpected happened"
            case .unableToPublishChanges:
                return "We were unable to publish your changes in the network"
            }
        }
    }
}

fileprivate struct NosNIP05Field: View {
    
    var username: String
    @Binding var showConfirmationDialog: Bool

    var body: some View {
        NosFormField(label: .localizable.username) {
            VStack(alignment: .leading) {
                HStack(spacing: 0) {
                    Group {
                        Text(username)
                            .foregroundColor(.primaryTxt)
                        Text("@nos.social")
                            .foregroundStyle(Color.secondaryTxt)
                    }
                    Spacer(minLength: 10)
                    Button {
                        showConfirmationDialog = true
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color.nip05FieldFgGradientTop,
                                        Color.nip05FieldFgGradientBottom
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .background {
                                Circle().fill(Color.white).padding(3)
                            }
                            .shadow(radius: 2, y: 2)
                    }
                }
                .padding(.vertical, 15)
                (
                    Text(Image(systemName: "exclamationmark.triangle"))
                        .foregroundStyle(Color.nip05FieldTextForeground) +
                    Text(" ") +
                    Text(.localizable.usernameWarningMessage)
                        .foregroundStyle(Color.secondaryTxt)
                )
                .font(.footnote)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

fileprivate struct NIP05Field: View {

    var nip05: String
    @Binding var showConfirmationDialog: Bool
    
    var body: some View {
        NosFormField(
            label: .localizable.username
        ) {
            VStack {
                HStack {
                    Text(nip05)
                        .foregroundColor(.primaryTxt)
                    Spacer()
                    Button {
                        showConfirmationDialog = true
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color.nip05FieldFgGradientTop,
                                        Color.nip05FieldFgGradientBottom
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .background {
                                Circle().fill(Color.white).padding(3)
                            }
                            .shadow(radius: 2, y: 2)
                    }
                }
                .padding(.vertical, 15)
                (
                    Text(Image(systemName: "exclamationmark.triangle"))
                        .foregroundStyle(Color.nip05FieldTextForeground) +
                    Text(" ") +
                    Text(.localizable.usernameWarningMessage)
                        .foregroundStyle(Color.secondaryTxt)
                )
                .font(.footnote)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

fileprivate struct NosNIP05Banner: View {

    @Binding var showNIP05Wizard: Bool

    var body: some View {
        NosFormField(label: .localizable.username) {
            ActionBanner(
                messageText: .localizable.claimYourUsernameText,
                messageImage: .atSymbol,
                buttonText: .localizable.claimYourUsernameButton
            ) {
                showNIP05Wizard = true
            }
            .padding(.top, 13)
        }
    }
}

struct ProfileEditView_Previews: PreviewProvider {
    
    static var previewData = PreviewData()

    static var previews: some View {
        NavigationStack {
            ProfileEditView(author: previewData.alice)
                .inject(previewData: previewData)
        }
    }
}
