import SwiftUI

struct BeveledContainerView<Content: View>: View {
    let content: () -> Content
    
    var topColor: Color = .buttonBevelBottom
    var bottomColor: Color = .panelBevelBottom
    
    var body: some View {
        VStack(spacing: 0) {
            HorizontalLine(color: topColor)
            
            content()
            
            HorizontalLine(color: bottomColor, height: 1 / UIScreen.main.scale)
            
            HorizontalLine(color: .black, height: 1 / UIScreen.main.scale)
        }
    }
}
