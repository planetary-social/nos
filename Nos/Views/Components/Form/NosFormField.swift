import SwiftUI
import SwiftUINavigation

struct NosFormField<Control: View>: View {

    let control: Control
    let label: LocalizedStringKey
    @FocusState private var focus: Bool

    init(
        _ label: LocalizedStringKey,
        @ViewBuilder builder: () -> Control
    ) {
        self.label = label
        self.control = builder()
    }
    
    var body: some View {
        VStack {
            HStack {
                Text(label)
                    .foregroundColor(.secondaryTxt)
                    .font(.clarity(.medium, textStyle: .subheadline))
                Spacer()
            }
            
            control
                .accessibilityLabel(label)
                .focused($focus)
        }
        .padding(16)
        .contentShape(Rectangle())
        .onTapGesture {
            focus = true
        }
    }
}

struct NosFormField_Previews: PreviewProvider {
    static var previews: some View {
        NosForm {
            NosFormSection("profileTitle") {
                WithState(initialValue: "") { text in
                    NosFormField("about") {
                        TextField("", text: text)
                            .textInputAutocapitalization(.never)
                            .foregroundColor(.primaryTxt)
                            .autocorrectionDisabled()
                    }
                }
            }
        }
    }
}
