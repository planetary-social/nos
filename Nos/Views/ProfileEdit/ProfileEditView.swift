//
//  ProfileEditView.swift
//  Nos
//
//  Created by Christopher Jorgensen on 3/9/23.
//

import Dependencies
import SwiftUI

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

    init(author: Author) {
        self.author = author
        self.unsController.authorKey = author.hexadecimalPublicKey
    }
    
    var body: some View {
        NosForm {
            AvatarView(imageUrl: URL(string: avatarText), size: 99)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
                .padding(.top, 16)
            
            NosFormSection(label: .localizable.profilePicture) {
                NosTextField(label: .localizable.url, text: $avatarText)
                    #if os(iOS)
                    .keyboardType(.URL)
                    #endif
            }
            
            HStack {
                HighlightedText(
                    text: .localizable.uploadProfilePicInstructions,
                    highlightedWord: "nostr.build",
                    highlight: .diagonalAccent,
                    textColor: .secondaryTxt,
                    font: .footnote,
                    link: URL(string: "https://nostr.build")!
                )
                Spacer()
            }
            .padding(13)
            
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
                unsController = UNSWizardController(authorKey: author.hexadecimalPublicKey)
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
                    // Go back to profile page
                    router.pop()
                }
                .offset(y: -3)
        )
        .id(author)
        .task {
            populateTextFields()
        }
        .onDisappear {
            currentUser.editing = false
        }
    }

    func populateTextFields() {
        viewContext.refresh(author, mergeChanges: true)
        nameText = author.name ?? author.displayName ?? ""
        bioText = author.about ?? ""
        avatarText = author.profilePhotoURL?.absoluteString ?? ""
        website = author.website ?? ""
        unsText = author.uns ?? ""
    }
    
    func save() async {
        author.name = nameText
        author.about = bioText
        author.profilePhotoURL = URL(string: avatarText)
        author.website = website
        author.uns = unsText
        do {
            try viewContext.save()
            // Post event
            await currentUser.publishMetaData()
        } catch {
            crashReporting.report(error)
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
                        PlainText(username)
                            .foregroundColor(.primaryTxt)
                        PlainText("@nos.social")
                            .foregroundStyle(Color.secondaryTxt)
                    }
                    Spacer(minLength: 10)
                    Button {
                        showConfirmationDialog = true
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "#E55121"), Color(hex: "#A42509")],
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
                        .foregroundStyle(Color(hex: "#F0A108")) +
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
                                    colors: [Color(hex: "#E55121"), Color(hex: "#A42509")],
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
                        .foregroundStyle(Color(hex: "#F0A108")) +
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
