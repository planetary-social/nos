import TipKit

/// A popover tip view style that has a point down emoji (👇) in the bottom left in addition to the title and
/// close button.
struct PointDownEmojiTipViewStyle: TipViewStyle {
    func makeBody(configuration: TipViewStyle.Configuration) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                configuration.title
                    .font(.body.bold())
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

            Text("👇")
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
    }
}

extension TipViewStyle where Self == PointDownEmojiTipViewStyle {
    static var pointDownEmoji: Self { Self() }
}
