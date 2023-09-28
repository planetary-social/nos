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
    @EnvironmentObject private var currentUser: CurrentUser
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
    
    var nip05: Binding<String> {
        Binding<String>(
            get: { self.nip05Text },
            set: { self.nip05Text = $0.lowercased() }
        )
    }
    
    init(author: Author) {
        self.author = author
    }
    
    var body: some View {
        ScrollView {
            AvatarView(imageUrl: author.profilePhotoURL, size: 99)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
                .padding(.top, 16)
            
            NosFormSection(label: .profilePicture) {
                NosTextField(label: .url, text: $avatarText)
                    #if os(iOS)
                    .keyboardType(.URL)
                    #endif
            }
            
            HighlightedText(
                text: .uploadProfilePicInstructions,
                highlightedWord: "nostr.build", 
                highlight: .diagonalAccent, 
                font: .clarityCaption,
                link: URL(string: "https://nostr.build")!
            )
            .padding(13)
            
            NosFormSection(label: .basicInfo) { 
                NosTextField(label: .name, text: $nameText)
                BeveledSeparator()
                NosTextEditor(label: .bio, text: $bioText)
                    .frame(maxHeight: 200)
                BeveledSeparator()
                NosTextField(label: .website, text: $website)
            }
            
            NosFormSection(label: .identityVerification) { 
                NosTextField(label: .nip05, text: $nip05Text)
            }
            
            HStack {
                HighlightedText(
                    text: .nip05LearnMore,
                    highlightedWord: Localized.learnMore.string, 
                    highlight: .diagonalAccent, 
                    font: .clarityCaption,
                    link: URL(string: "https://nostr.how/en/guides/get-verified")!
                )
                Spacer()
            }
            .padding(13)
                
            // Universal Names Set Up
            if author.nip05?.hasSuffix("universalname.space") != true {
                SetUpUNSBanner {
                    showUniversalNameWizard = true
                }
                .padding(13)
            }
        }
        .sheet(isPresented: $showUniversalNameWizard, content: {
            UniversalNameWizard(author: author) {
                populateTextFields()
                self.showUniversalNameWizard = false
            }
        })
        .scrollContentBackground(.hidden)
        .background(Color.appBg)
        .nosNavigationBar(title: .profileTitle)
        .navigationBarBackButtonHidden()
        .navigationBarItems(
            leading: Button(Localized.cancel.string, action: { 
                router.pop()
            }),
            trailing:
                ActionButton(title: .done) {
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
        NavigationView {
            ProfileEditView(author: previewData.alice)
                .inject(previewData: previewData)
        }
    }
}
