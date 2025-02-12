import SwiftUI

/// A view that displays one or more lines of read-only text presented as a description.
///
///
/// This Text was implemented to be re-used in the wizards that set-up and delete usernames in EditProfile screen.
struct WizardSheetDescriptionText: View {

    private let description: Description

    private enum Description {
        case plainText(LocalizedStringResource)
        case markdown(AttributedString)
        
        var text: Text {
            switch self {
            case .plainText(let localizedStringResource):
                return Text(localizedStringResource)
            case .markdown(let attributedString):
                return Text(attributedString)
            }
        }
    }

    init(_ localizedStringResource: LocalizedStringResource) {
        self.description = .plainText(localizedStringResource)
    }

    init(_ attributedString: AttributedString, tint: Color) {
        self.description = .markdown(attributedString
            .replacingAttributes(
                AttributeContainer(
                    [.inlinePresentationIntent: InlinePresentationIntent.stronglyEmphasized.rawValue]
                ),
                with: AttributeContainer(
                    [.foregroundColor: UIColor(tint)]
                )
            ))
    }

    init(
        markdown: AttributedString,
        tint: Color = .primaryTxt
    ) {
        self.init(
            markdown,
            tint: tint
        )
    }

    var body: some View {
        description.text
            .font(.clarity(.medium, textStyle: .subheadline))
            .lineSpacing(5)
            .foregroundStyle(Color.secondaryTxt)
    }
}

#Preview {
    VStack(spacing: 10) {
        WizardSheetDescriptionText(LocalizedStringResource(stringLiteral: "Hello"))
        WizardSheetDescriptionText(LocalizedStringResource(stringLiteral: "Hello **Martin**"))
        WizardSheetDescriptionText(markdown: AttributedString("Hello **Martin**"))
    }
}
