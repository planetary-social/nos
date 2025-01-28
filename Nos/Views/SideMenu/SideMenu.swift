import Foundation
import SwiftUI
import Dependencies

struct SideMenu: View {
    
    enum Destination {
        case settings
        case relays
        case lists
        case profile
        case about
    }
    
    let menuWidth: CGFloat
    let menuOpened: Bool
    
    let toggleMenu: @MainActor () -> Void
    let closeMenu: @MainActor () -> Void
    
    @EnvironmentObject private var router: Router
    @Dependency(\.analytics) private var analytics
    
    var body: some View {
        if menuOpened {
            ZStack {
                GeometryReader { _ in
                    EmptyView()
                }
                .background(Color.black.opacity(0.5))
                .onTapGesture {
                    self.toggleMenu()
                }
            }
            HStack {
                SideMenuContent(closeMenu: closeMenu)
                    .frame(
                        maxWidth: router.sideMenuPath.count == 0 ? menuWidth : .infinity,
                        maxHeight: .infinity
                    )
                Spacer()
            }
            .transition(.move(edge: .leading))
            // weirdly fixes dismissal animation
            // https://sarunw.com/posts/how-to-fix-zstack-transition-animation-in-swiftui/#solution
            .zIndex(1)
            .onAppear {
                analytics.showedSideMenu()
            }
        }
    }
}

struct SideMenu_Previews: PreviewProvider {
    
    static var previewData = PreviewData()
    static var menuOpened = true
    
    static var previews: some View {
        SideMenu(
            menuWidth: 300, 
            menuOpened: menuOpened, 
            toggleMenu: { 
                menuOpened.toggle()
            }, closeMenu: { 
                menuOpened = false
            }
        )
        .inject(previewData: previewData)
    }
}
