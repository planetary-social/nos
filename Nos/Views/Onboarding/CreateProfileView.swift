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

    var currentUser: CurrentUser
    var createAccountCompletion: (() -> Void)?
    
    @Environment(\.managedObjectContext) private var viewContext
    @Dependency(\.analytics) private var analytics
    
    init(user: CurrentUser, createAccountCompletion: (() -> Void)? = nil) {
        self.currentUser = user
        self.createAccountCompletion = createAccountCompletion
    }
    
    var body: some View {
        ProfileEditView(author: currentUser.author!, createAccountCompletion: createAccountCompletion)
    }
}
