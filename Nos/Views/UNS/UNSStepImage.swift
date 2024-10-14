import SwiftUI

struct UNSStepImage<Content: View>: View {

    let image: Content
    let size: CGFloat = 178

    @Environment(\.colorScheme) var colorScheme: ColorScheme

    init(@ViewBuilder builder: () -> Content) {
        self.image = builder()
    }

    var body: some View {
        ZStack {
            Circle()
                .foregroundColor(.init(.unsLogoBackground))
            Image.unsCircle.opacity(colorScheme == .dark ? 0.15 : 1)
            image
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    UNSStepImage { Image.unsVerificationCode }
}
