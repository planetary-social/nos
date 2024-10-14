import SwiftUI
import SwiftUINavigation

struct NosFormSection<Content: View>: View {

    var label: LocalizedStringResource?
    let content: Content

    init(label: LocalizedStringResource? = nil, @ViewBuilder builder: () -> Content) {
        self.label = label
        self.content = builder()
    }

    var body: some View {
        VStack {
            if let label {
                HStack {
                    Text(label)
                        .font(.clarity(.semibold, textStyle: .headline))
                        .foregroundColor(.primaryTxt)
                        .padding(.top, 16)

                    Spacer()
                }
            }

            ZStack {
                // 3d card effect
                ZStack {
                    Color.card3d
                }
                .cornerRadius(21)
                .offset(y: 4.5)
                .shadow(
                    color: Color.lightShadow,
                    radius: 2,
                    x: 0,
                    y: 0
                )

                VStack {
                    content
                }
                .background(LinearGradient.cardGradient)
                .cornerRadius(20)
            }
        }
        .padding(.horizontal, 13)
    }
}

struct NosFormSection_Previews: PreviewProvider {
    static var previews: some View {
        NosForm {
            NosFormSection(label: .localizable.profilePicture) {
                WithState(initialValue: "Alice") { text in
                    NosTextField(label: .localizable.url, text: text)
                }
            }
        }
    }
}
