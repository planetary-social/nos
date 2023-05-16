//
//  ProfileEditView.swift
//  Nos
//
//  Created by Christopher Jorgensen on 3/9/23.
//

import SwiftUI

struct ProfileEditView: View {
    
    @EnvironmentObject private var relayService: RelayService
    @EnvironmentObject private var router: Router
    @Environment(\.managedObjectContext) private var viewContext

    @ObservedObject var author: Author
    
    @State private var displayNameText: String = ""
    @State private var nameText: String = ""
    @State private var bioText: String = ""
    @State private var avatarText: String = ""
    @State private var unsText: String = ""
    @State private var nip05Text: String = ""
    @State private var showUniversalNameWizard = false
    
    var createAccountCompletion: (() -> Void)?
    
    init(author: Author, createAccountCompletion: (() -> Void)? = nil) {
        self.author = author
        self.createAccountCompletion = createAccountCompletion
    }
    
    var body: some View {
        VStack {
            Form {
                Section {
                    TextField(text: $displayNameText) {
                        Localized.displayName.view.foregroundColor(.secondaryText)
                    }
                    .textInputAutocapitalization(.none)
                    .foregroundColor(.textColor)
                    .autocorrectionDisabled()
                    TextField(text: $nameText) {
                        Localized.name.view.foregroundColor(.secondaryText)
                    }
                    .textInputAutocapitalization(.none)
                    .foregroundColor(.textColor)
                    .autocorrectionDisabled()
                    TextEditor(text: $bioText)
                        .placeholder(when: bioText.isEmpty, placeholder: {
                            Text(Localized.bio.string)
                                .foregroundColor(.secondaryText)
                        })
                        .foregroundColor(.textColor)
                    TextField(text: $avatarText) {
                        Localized.picUrl.view.foregroundColor(.secondaryText)
                    }
                    .foregroundColor(.textColor)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.none)
                    #if os(iOS)
                    .keyboardType(.URL)
                    #endif
                    let nip05Binding = Binding<String>(
                        get: { self.nip05Text },
                        set: { self.nip05Text = $0.lowercased() }
                    )
                    TextField(text: nip05Binding) {
                        Localized.nip05.view.foregroundColor(.secondaryText)
                    }
                    .textInputAutocapitalization(.none)
                    .foregroundColor(.textColor)
                    .autocorrectionDisabled()
                } header: {
                    createAccountCompletion != nil ? Localized.createAccount.view : Localized.basicInfo.view
                        .foregroundColor(.textColor)
                        .fontWeight(.heavy)
                }
                .listRowBackground(LinearGradient(
                    colors: [Color.cardBgTop, Color.cardBgBottom],
                    startPoint: .top,
                    endPoint: .bottom
                ))
            }
            if let createAccountCompletion {
                Spacer()
                BigActionButton(title: .createAccount) {
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
            CurrentUser.shared.editing = false
        }
    }
   
    func populateTextFields() {
        displayNameText = author.displayName ?? ""
        nameText = author.name ?? ""
        bioText = author.about ?? ""
        avatarText = author.profilePhotoURL?.absoluteString ?? ""
        nip05Text = author.nip05 ?? ""
        unsText = author.uns ?? ""
    }
    
    func save() async {
        author.displayName = displayNameText
        author.name = nameText
        author.about = bioText
        author.profilePhotoURL = URL(string: avatarText)
        author.nip05 = nip05Text
        author.uns = unsText
        try! viewContext.save()
        // Post event
        await CurrentUser.shared.publishMetaData()
    }
}

struct ProfileEditView_Previews: PreviewProvider {
    
    static var persistenceController = PersistenceController.preview
    static var previewContext = persistenceController.container.viewContext

    static var author: Author {
        let author = Author(context: previewContext)
        author.hexadecimalPublicKey = KeyFixture.pubKeyHex
        return author
    }
    
    static var previews: some View {
        ProfileEditView(author: author)
    }
}
