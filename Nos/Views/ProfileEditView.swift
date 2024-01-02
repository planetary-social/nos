//
//  ProfileEditView.swift
//  Nos
//
//  Created by Christopher Jorgensen on 3/9/23.
//

import Dependencies
import SwiftUI

struct ProfileEditView: View {
    
    @EnvironmentObject private var relayService: RelayService
    @EnvironmentObject private var router: Router
    @Environment(CurrentUser.self) private var currentUser
    @Environment(\.managedObjectContext) private var viewContext

    @Dependency(\.crashReporting) private var crashReporting

    @ObservedObject var author: Author
    
    @State private var nameText: String = ""
    @State private var bioText: String = ""
    @State private var avatarText: String = ""
    @State private var unsText: String = ""
    @State private var nip05Text: String = ""
    @State private var website: String = ""
    @State private var showUniversalNameWizard = false
    @State private var unsController = UNSWizardController()
    
    var nip05: Binding<String> {
        Binding<String>(
            get: { self.nip05Text },
            set: { self.nip05Text = $0.lowercased() }
        )
    }
    
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
                    font: .clarityCaption,
                    link: URL(string: "https://nostr.build")!
                )
                Spacer()
            }
            .padding(13)
            
            NosFormSection(label: .localizable.basicInfo) {
                NosTextField(label: .localizable.name, text: $nameText)
                FormSeparator()
                NosTextEditor(label: .localizable.bio, text: $bioText)
                    .frame(maxHeight: 200)
                FormSeparator()
                NosTextField(label: .localizable.website, text: $website)
            }
            
            HStack {
                Text(.localizable.identityVerification)
                    .font(.clarityTitle3)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryTxt)
                    .padding(.top, 16)
                
                Spacer()
            }
            .padding(.horizontal, 13)
            
            SetUpUNSBanner {
                showUniversalNameWizard = true
            }
            .padding(13)
            
            NosFormSection(label: nil) { 
                NosTextField(label: .localizable.universalName, text: $unsText)
                NosTextField(label: .localizable.nip05, text: $nip05Text)
            }
            
            HStack {
                HighlightedText(
                    text: .localizable.nip05LearnMore,
                    highlightedWord: String(localized: .localizable.learnMore), 
                    highlight: .diagonalAccent, 
                    font: .clarityCaption,
                    link: URL(string: "https://nostr.how/en/guides/get-verified")!
                )
                Spacer()
            }
            .padding(13)
        }
        .sheet(isPresented: $showUniversalNameWizard, content: {
            UNSWizard(controller: unsController, isPresented: $showUniversalNameWizard)
        })
        .onChange(of: showUniversalNameWizard) { _, newValue in
            if !newValue {
                nip05Text = currentUser.author?.nip05 ?? ""
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
        nip05Text = author.nip05 ?? ""
        unsText = author.uns ?? ""
    }
    
    func save() async {
        author.name = nameText
        author.about = bioText
        author.profilePhotoURL = URL(string: avatarText)
        author.website = website
        author.nip05 = nip05Text
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

struct ProfileEditView_Previews: PreviewProvider {
    
    static var previewData = PreviewData()

    static var previews: some View {
        NavigationStack {
            ProfileEditView(author: previewData.alice)
                .inject(previewData: previewData)
        }
    }
}
