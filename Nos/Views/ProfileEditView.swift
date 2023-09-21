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
    
    @State private var displayNameText: String = ""
    @State private var nameText: String = ""
    @State private var bioText: String = ""
    @State private var avatarText: String = ""
    @State private var unsText: String = ""
    @State private var nip05Text: String = ""
    @State private var website: String = ""
    @State private var showUniversalNameWizard = false
    
    var createAccountCompletion: (() -> Void)?
    
    var nip05: Binding<String> {
        Binding<String>(
            get: { self.nip05Text },
            set: { self.nip05Text = $0.lowercased() }
        )
    }
    
    init(author: Author, createAccountCompletion: (() -> Void)? = nil) {
        self.author = author
        self.createAccountCompletion = createAccountCompletion
    }
    
    var body: some View {
        ScrollView {
            AvatarView(imageUrl: author.profilePhotoURL, size: 99)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
            
            NosFormSection(label: .profilePicture) {
                NosTextField(label: .url, text: $avatarText)
            }
            
            HighlightedText(
                text: .uploadProfilePicInstructions,
                highlightedWord: "nostr.build", 
                highlight: .diagonalAccent, 
                font: .clarityCaption,
                link: URL(string: "https://nostr.build")!
            )
            .padding(.vertical)
            
            NosFormSection(label: .basicInfo) { 
                NosTextField(label: .name, text: $displayNameText)
                BeveledSeparator()
                NosTextEditor(label: .bio, text: $bioText)
                    .frame(maxHeight: 200)
#if os(iOS)
                    .keyboardType(.URL)
#endif
                BeveledSeparator()
                NosTextField(label: .website, text: $website)
            }
            
            //        header: {
            //                    createAccountCompletion != nil ? Localized.tryIt.view : Localized.basicInfo.view
            //                        .foregroundColor(.primaryTxt)
            //                        .fontWeight(.heavy)
            //                }
                
                // Universal Names Set Up
//                if author.nip05?.hasSuffix("universalname.space") != true {
//                    SetUpUNSBanner {
//                        showUniversalNameWizard = true
//                    }
//                }
            
            if let createAccountCompletion {
                Spacer()
                BigActionButton(title: .tryIt) {
                    await save()
                    createAccountCompletion()
                }
                .background(Color.appBg)
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
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
        .nosNavigationBar(title: .editProfile)
        .navigationBarItems(
            trailing:
                Group {
                    if createAccountCompletion == nil {
                        Button(
                            action: {
                                Task { await save() }
                                
                                // Go back to profile page
                                router.pop()
                            },
                            label: {
                                Text(Localized.done.string)
                            }
                        )
                    }
                }
        )
        .task {
            populateTextFields()
        }
        .onDisappear {
            currentUser.editing = false
        }
    }
   
    func populateTextFields() {
        displayNameText = author.displayName ?? ""
        nameText = author.name ?? ""
        bioText = author.about ?? ""
        avatarText = author.profilePhotoURL?.absoluteString ?? ""
        website = author.website ?? ""
        nip05Text = author.nip05 ?? ""
        unsText = author.uns ?? ""
    }
    
    func save() async {
        author.displayName = displayNameText
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
        ProfileEditView(author: previewData.alice)
            .inject(previewData: previewData)
    }
}

struct NosFormSection<Content: View>: View {
    
    var label: Localized
    let content: Content
    
    init(label: Localized, @ViewBuilder builder: () -> Content) {
        self.label = label
        self.content = builder()
    }
    
    var body: some View {
        VStack {
            HStack {
                Text(label)
                    .font(.claritySubheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryTxt)
                    .padding(.top, 16)
                
                Spacer()
            }
            
            ZStack {
                // 3d card effect
                ZStack {
                    Color.cardBorderBottom
                }
                .cornerRadius(21)
                .offset(y: 4.5)
                .shadow(
                    color: Color(white: 0, opacity: 0.2), 
                    radius: 2, 
                    x: 0, 
                    y: 0
                )
                
                VStack {
                    content
                }
                .background(LinearGradient.cardGradient)
                .cornerRadius(20)
                .readabilityPadding()
            }
        }
        .padding(.horizontal, 13)
    }
}

struct BeveledSeparator: View {
    
    typealias TableRowBody = Divider
    
    var body: some View {
        Divider()
            .overlay(Color.cardDivider)
            .shadow(color: .cardDividerShadow, radius: 0, x: 0, y: 1)
    }
}

struct NosTextField: View {
    
    var label: Localized
    @Binding var text: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondaryText)
                .fontWeight(.medium)
                .font(.clarityCallout)
            
            TextField("", text: $text)
                .accessibilityLabel(label.string)
                .textInputAutocapitalization(.none)
                .foregroundColor(.primaryTxt)
                .autocorrectionDisabled()
        }
        .padding(16)
    }
}

struct NosTextEditor: View {
    
    var label: Localized
    @Binding var text: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondaryText)
                .fontWeight(.medium)
                .font(.clarityCallout)
            
            TextEditor(text: $text)
                .accessibilityLabel(label.string)
                .textInputAutocapitalization(.none)
                .foregroundColor(.primaryTxt)
                .autocorrectionDisabled()
        }
        .padding(16)
    }
}
