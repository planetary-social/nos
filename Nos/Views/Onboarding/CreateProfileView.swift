//
//  CreateProfileView.swift
//  Nos
//
//  Created by Matthew Lorentz on 3/18/23.
//

import SwiftUI
import Dependencies
import CoreData

struct CreateProfileView: View {

    @State var author: Author?
    var currentUser: CurrentUser
    var createAccountCompletion: (() -> Void)?
    
    @Environment(\.managedObjectContext) private var viewContext
    @Dependency(\.analytics) private var analytics
    
    @State var loaded = false
    
    func createAccountAndLoadAuthor() {
        let keyPair = KeyPair()!
        currentUser.keyPair = keyPair
        analytics.generatedKey()
        
        // Recommended Relays for new user
        for address in Relay.recommended {
            _ = try? Relay(
                context: viewContext,
                address: address,
                author: currentUser.author
            )
        }
        let author = currentUser.author!
        try? viewContext.save()
        
        currentUser.publishContactList(tags: [])
        
        self.author = author
    }
    
    init(user: CurrentUser, createAccountCompletion: (() -> Void)? = nil) {
        self.currentUser = user
        self.createAccountCompletion = createAccountCompletion
    }
    
    var body: some View {
        if let author {
            ProfileEditView(author: author, createAccountCompletion: createAccountCompletion)
        } else {
            ProgressView()
                .background(Color.appBg)
                .task {
                    createAccountAndLoadAuthor()
                }
        }
    }
}
