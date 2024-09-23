import SwiftUI

struct SideMenuButton: View {
    
    @EnvironmentObject private var router: Router
    
    var body: some View {
        Button {
            router.toggleSideMenu()
        } label: {
            Image.sideMenu
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 24)
        }
    }
}

struct SideMenuButton_Previews: PreviewProvider {
    static var previews: some View {
        SideMenuButton()
    }
}
