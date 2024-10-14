import SwiftUI
import SwiftUINavigation

struct UNSWizardTextField: View {

    var text: Binding<String>
    var placeholder: String = ""

    var body: some View {
        TextField(text: text) {
            Text(placeholder)
                .foregroundColor(.secondaryTxt)
        }
        .font(.clarity(.bold, textStyle: .title2))
        .foregroundColor(.primaryTxt)
        .multilineTextAlignment(.center)
        .padding(19)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondaryTxt, lineWidth: 2)
                .background(Color.textFieldBg)
        )
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(String(localized: .localizable.done)) {
                    hideKeyboard()
                }
            }
        }
        .padding(.vertical, 40)
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct WizardTextField_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            WithState(initialValue: "") { text in
                UNSWizardTextField(text: text, placeholder: "12345578")
                    .padding()
            }
        }
        .background(Color.appBg)
    }
}
