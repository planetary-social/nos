//
//  ProfileTab.swift
//  Nos
//
//  Created by Matthew Lorentz on 3/9/23.
//

import SwiftUI

/// A version of the ProfileView that is displayed in the main tab bar
struct ProfileTab: View {
    
    @ObservedObject var author: Author
    
    @Binding var path: NavigationPath
    
    @EnvironmentObject private var router: Router

    var body: some View {
        NavigationStack(path: $path) {
            ProfileView(author: author)
                .navigationBarItems(
                    leading:
                        Button(
                            action: {
                                router.toggleSideMenu()
                            },
                            label: {
                                Image(systemName: "line.3.horizontal")
                                    .foregroundColor(.nosSecondary)
                            }
                        )
                )
        }
    }
}
