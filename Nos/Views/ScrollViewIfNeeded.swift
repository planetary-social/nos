import SwiftUI

/// A view that places its contents in a ScrollView if they exceed the available space.
/// This is useful because some views won't expand to fill the available
/// space when they are put in a ScrollView.
struct ScrollViewIfNeeded<Content>: View where Content: View {
    @ViewBuilder var content: Content
    
    var body: some View {
        ViewThatFits {
            content 
            ScrollView {
                content
            }
        } 
    }
}

#Preview {
    ScrollViewIfNeeded {
        // This view is small and won't scroll 
        GridPattern()
            .frame(height: 400)
    }
}

#Preview {
    // This view exceeds the screen bounds and should scroll
    ScrollViewIfNeeded {
        GridPattern()
            .frame(height: 4000)
    }
}
