import TipKit

/// An inline tip view style with a styled title, message, and close button.
struct InlineTipViewStyle: TipViewStyle {
    func makeBody(configuration: TipViewStyle.Configuration) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                configuration.title
                    .font(.title2.bold())
                    .foregroundStyle(Color.primaryTxt)
                    .shadow(color: .lightShadow, radius: 2, x: 0, y: 1)
                Spacer()
                Button {
                    configuration.tip.invalidate(reason: .tipClosed)
                } label: {
                    Image(systemName: "xmark").scaledToFit()
                        .foregroundStyle(Color.primaryTxt)
                        .font(.system(size: 20).bold())
                }
            }

            configuration.message
                .foregroundStyle(Color.primaryTxt)
                .shadow(color: .lightShadow, radius: 2, x: 0, y: 1)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
    }
}

extension TipViewStyle where Self == InlineTipViewStyle {
    static var inline: Self { Self() }
}
