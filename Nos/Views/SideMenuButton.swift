//
//  SideMenuButton.swift
//  Nos
//
//  Created by Matthew Lorentz on 3/18/23.
//

import SwiftUI

struct SideMenuButton: View {
    
    @EnvironmentObject var router: Router
    
    var body: some View {
        Button {
            router.toggleSideMenu()
        } label: {
            Image.sideMenu
        }
    }
}

struct SideMenuButton_Previews: PreviewProvider {
    static var previews: some View {
        SideMenuButton()
    }
}
