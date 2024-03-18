import SwiftUI

struct FormSeparator: View {
    var body: some View {
        Color.cardDividerBottom
            .frame(height: 2)
            .shadow(color: .cardDividerBottomShadow, radius: 0, x: 0, y: 2)
    }
}

struct BeveledSeparator: View {
    var body: some View {
        Color.cardDividerBottom
            .frame(height: 1)
            .shadow(color: .cardDividerBottomShadow, radius: 0, x: 0, y: 1)
    }
}

struct BeveledSeparator_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Text("hello")
            FormSeparator()
            Text("world")
            BeveledSeparator()
            Text("world")
        }
        .background(Color.appBg)
    }
}
