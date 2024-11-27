import SwiftUI
import SwiftUINavigation

struct NosTextEditor: View {
    
    var label: LocalizedStringKey
    @Binding var text: String
    
    init(_ label: LocalizedStringKey, text: Binding<String>) {
        self.label = label
        self._text = text
    }
    
    var body: some View {
        NosFormField(label) {
            TextEditor(text: $text)
                .textInputAutocapitalization(.never)
                .foregroundColor(.primaryTxt)
                .scrollContentBackground(.hidden)
                .autocorrectionDisabled()
        }
    }
}

struct NosTextEditor_Previews: PreviewProvider {
    static var previews: some View {
        NosForm {
            NosFormSection("profilePicture") {
                WithState(initialValue: "Alice") { text in
                    NosTextEditor("bio", text: text)
                        .frame(maxHeight: 200)
                }
            }
        }
    }
}
