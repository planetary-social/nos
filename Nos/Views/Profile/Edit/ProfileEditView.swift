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
    
    @State private var displayNameText: String = ""
    @State private var bioText: String = ""
    @State private var avatarText: String = ""
    @State private var website: String = ""
    @State private var pronouns: String = ""
    @State private var showNIP05Wizard = false
    @State private var showConfirmationDialog = false
    @State private var saveError: SaveProfileError?
    
    @State private var isUploadingPhoto = false

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
            
            NosFormSection("profilePicture") {
                NosTextField("url", text: $avatarText)
                    #if os(iOS)
                    .keyboardType(.URL)
                    #endif
            }
            
            NosFormSection("basicInfo") {
                NosTextField("displayName", text: $displayNameText)
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
                NosTextEditor("bio", text: $bioText)
                    .frame(maxHeight: 200)
                FormSeparator()
                NosTextField("website", text: $website)
                FormSeparator()
                NosTextField("pronouns", text: $pronouns)
            }
        }
        .sheet(isPresented: $showNIP05Wizard) {
            CreateUsernameWizard(isPresented: $showNIP05Wizard)
        }
        .sheet(isPresented: $showConfirmationDialog) {
            DeleteUsernameWizard(
                author: author,
                isPresented: $showConfirmationDialog
            )
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBg)
        .nosNavigationBar("profileTitle")
        .navigationBarBackButtonHidden()
        .navigationBarItems(
            leading: Button("cancel", action: { 
                router.pop()
            }),
            trailing:
                ActionButton("done") {
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
                Text("retry")
            }
            Button {
                saveError = nil
            } label: {
                Text("cancel")
            }
        }
        .id(author)
        .task {
            populateTextFields()
        }
    }

    private func populateTextFields() {
        viewContext.refresh(author, mergeChanges: true)
        displayNameText = (author.displayName?.isEmpty == true ? author.name : author.displayName) ?? ""
        bioText = author.about ?? ""
        avatarText = author.profilePhotoURL?.absoluteString ?? ""
        website = author.website ?? ""
        pronouns = author.pronouns ?? ""
    }
    
    private func save() async {
        author.displayName = displayNameText
        author.about = bioText
        author.profilePhotoURL = URL(string: avatarText)
        author.website = website
        author.pronouns = pronouns
        do {
            try viewContext.save()
            try await currentUser.publishMetadata()

            // Go back to profile page
            router.pop()
        } catch CurrentUserError.errorWhilePublishingToRelays {
            saveError = SaveProfileError.unableToPublishChanges
        } catch {
            crashReporting.report(error)
            saveError = SaveProfileError.unexpectedError
        }
    }
}

fileprivate struct NosNIP05Field: View {
    
    var username: String
    @Binding var showConfirmationDialog: Bool

    var body: some View {
        NosFormField("username") {
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
                    Text("usernameWarningMessage")
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
        NosFormField("username") {
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
                    Text("usernameWarningMessage")
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
        NosFormField("username") {
            ActionBanner(
                messageText: "claimYourUsernameText",
                messageImage: .atSymbol,
                buttonText: "claimYourUsernameButton",
                shouldButtonFillHorizontalSpace: false
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
