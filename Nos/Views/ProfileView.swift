//
//  ProfileView.swift
//  Nos
//
//  Created by Jason Cheatham on 2/20/23.
//

import Foundation
import SwiftUI
struct ProfileView: View {
    @EnvironmentObject var router: Router
   
    var profile: Profile
    var body: some View {
        Text("Profile view placeholder: \(profile.name)")
        .navigationBarBackButtonHidden(true)
        .onAppear {
            router.navigationTitle = "Profile"
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    
    static var previews: some View {
        Group {
            VStack {
                ProfileView(profile: Profile(name: "ProfileName"))
            }
        }
    }
}
