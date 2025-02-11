import SwiftUI

/// A view that displays a content view and arranges its subviews in a vertical line.
///
/// This View was implemented to be re-used in the wizards that set-up and delete usernames in EditProfile screen.
struct WizardSheetVStack<Content>: View where Content: View {

    private let content: () -> Content
    private let borderWidth: CGFloat = 6
    private let cornerRadius: CGFloat = 8
    private let inDrawer = true

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        ZStack {
            // Gradient border
            LinearGradient.diagonalAccent

            // Background color
            LinearGradient.nip05
                .cornerRadius(cornerRadius, corners: inDrawer ? [.topLeft, .topRight] : [.allCorners])
                .padding(.top, borderWidth)
                .padding(.horizontal, borderWidth)
                .padding(.bottom, inDrawer ? 0 : borderWidth)

            VStack(alignment: .leading, spacing: 20, content: content)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 40)
                .background {
                    VStack {
                        HStack(alignment: .top) {
                            Spacer()
                            Image.atSymbol
                                .aspectRatio(2, contentMode: .fit)
                                .blendMode(.softLight)
                                .scaleEffect(2)
                        }
                        .offset(x: 28, y: 20)
                        Spacer()
                    }
                }
                .padding(.top, borderWidth)
                .padding(.horizontal, borderWidth)
                .padding(.bottom, inDrawer ? 0 : borderWidth)
                .clipShape(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                )
        }
        .edgesIgnoringSafeArea(.bottom)
        .navigationBarBackButtonHidden()
    }
}

#Preview {
    WizardSheetVStack {
        Spacer(minLength: 40)
        Text("Hello")
        Spacer()
    }
}
