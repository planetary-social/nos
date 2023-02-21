//
//  SideMenuView.swift
//  Nos
//
//  Created by Jason Cheatham on 2/21/23.
//

import Foundation
import SwiftUI
struct SideMenu: View {
    let width: CGFloat
    let menuOpened: Bool
    
    let toggleMenu: () -> Void
    let closeMenu: () -> Void
    var body: some View {
        ZStack {
            GeometryReader { _ in
                EmptyView()
            }
            .background(Color.gray.opacity(0.5))
            .opacity(self.menuOpened ? 1 : 0)
            .animation(Animation.easeIn.delay(0.15))
            .onTapGesture {
                self.toggleMenu()
            }
        }
        HStack {
            SideMenuContent(closeMenu: closeMenu)
                .frame(width: width, height: UIScreen.main.bounds.height)
                .offset(x: menuOpened ? 0 : -width, y: -0.015*UIScreen.main.bounds.height)
                .animation(.default)
            Spacer()
        }
    }
}
