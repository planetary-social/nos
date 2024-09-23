import SwiftUI
import SwiftUINavigation

struct NosTextField: View {
    
    var label: LocalizedStringResource
    @Binding var text: String
    
    var body: some View {
        NosFormField(label: label) {
            TextField("", text: $text)
                .textInputAutocapitalization(.none)
                .foregroundColor(.primaryTxt)
                .autocorrectionDisabled()
        }
    }
}

struct NosTextField_Previews: PreviewProvider {
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
