import SwiftUI
import SwiftUINavigation

struct NosTextField: View {
    
    let label: LocalizedStringKey?
    @Binding var text: String
    
    init(_ label: LocalizedStringKey? = nil, text: Binding<String>) {
        self.label = label
        self._text = text
    }
    
    var body: some View {
        Group {
            if let label {
                NosFormField(label) {
                    TextField("", text: $text)
                }
            } else {
                TextField("", text: $text)
            }
        }
        .textInputAutocapitalization(.never)
        .foregroundColor(.primaryTxt)
        .autocorrectionDisabled()
    }
}

struct NosTextField_Previews: PreviewProvider {
    static var previews: some View {
        NosForm {
            NosFormSection("profilePicture") {
                WithState(initialValue: "Alice") { text in
                    NosTextField("url", text: text)
                }
            }   
        }
    }
}
