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
            Section(Localized.basicInfo.string) {
                TextField(Localized.displayName.string, text: $displayNameText)
                TextField(Localized.name.string, text: $nameText)
                TextField(Localized.bio.string, text: $bioText)
                TextField(Localized.picUrl.string, text: $avatarText)
            }
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
