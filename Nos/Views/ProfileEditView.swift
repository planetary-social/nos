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

    var author: Author
    
    @State private var displayNameText: String = ""
    @State private var nameText: String = ""
    @State private var bioText: String = ""
    @State private var avatarText: String = ""
    
    var body: some View {
        Form {
            Section {
                TextField(Localized.displayName.string, text: $displayNameText)
                    .textInputAutocapitalization(.none)
                    .foregroundColor(.textColor)
                    .autocorrectionDisabled()
                TextField(Localized.name.string, text: $nameText)
                    .textInputAutocapitalization(.none)
                    .foregroundColor(.textColor)
                    .autocorrectionDisabled()
                TextField(Localized.bio.string, text: $bioText)
                    .foregroundColor(.textColor)
                TextField(Localized.picUrl.string, text: $avatarText)
                    .foregroundColor(.textColor)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.none)
                    #if os(iOS)
                    .keyboardType(.URL)
                    #endif
            } header: {
                Localized.basicInfo.view
                    .foregroundColor(.textColor)
                    .fontWeight(.heavy)
            }
            .listRowBackground(LinearGradient(
                colors: [Color.cardBgTop, Color.cardBgBottom],
                startPoint: .top,
                endPoint: .bottom
            ))
        }
        .navigationBarItems(
            trailing:
                Group {
                    Button(
                        action: {
                            author.displayName = displayNameText
                            author.name = nameText
                            author.about = bioText
                            author.profilePhotoURL = URL(string: avatarText)

                            // Post event
                            CurrentUser.publishMetaData()

                            // Go back to profile page
                            router.pop()
                        },
                        label: {
                            Text(Localized.done.string)
                        }
                    )
                }
        )
        .task {
            displayNameText = author.displayName ?? ""
            nameText = author.name ?? ""
            bioText = author.about ?? ""
            avatarText = author.profilePhotoURL?.absoluteString ?? ""
        }
        .onDisappear {
            CurrentUser.editing = false
        }
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
