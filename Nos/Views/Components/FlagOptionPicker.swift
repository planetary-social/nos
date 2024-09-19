import SwiftUI
/// Displays a list of selectable flag options
struct FlagOptionPicker: View {
    @Binding private var selectedOption: FlagOption?
    var options: [FlagOption]
    var title: String
    var subtitle: String?

    init(selectedOption: Binding<FlagOption?>, options: [FlagOption], title: String, subtitle: String?) {
        self._selectedOption = selectedOption
        self.options = options
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading) {
            HeaderView(text: title)
            
            if let subtitle = subtitle {
                HeaderView(text: subtitle)
            }
            flagOptionsListView
        }
        .padding()
    }

    private var flagOptionsListView: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(options) { flag in
                FlagPickerRow(flag: flag, selection: $selectedOption)
                BeveledSeparator()
            }
        }
        .background(LinearGradient.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 15))
    }
}

/// A single row for a single flag option
struct FlagPickerRow: View {
    var flag: FlagOption
    @Binding var selection: FlagOption?

    var isSelected: Bool {
        selection?.id == flag.id
    }

    var body: some View {
        Button(action: {
            selection = flag
        }, label: {
            buttonLabel
        })
        .padding(14)
    }

    private var buttonLabel: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 8) {
                Text(flag.title)
                    .foregroundColor(.primaryTxt)
                    .font(.clarity(.regular))

                if let description = flag.description {
                    Text(description)
                        .foregroundColor(.secondaryTxt)
                        .multilineTextAlignment(.leading)
                        .font(.clarity(.regular, textStyle: .footnote))
                        .lineSpacing(8)
                }
            }
            Spacer()

            NosRadioButton(isSelected: isSelected)
        }
    }
}

private struct HeaderView: View {
    var text: String
    var body: some View {
        Text(text)
            .lineSpacing(5)
            .foregroundColor(.primaryTxt)
            .font(.clarity(.bold))
            .padding(.bottom, 28)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedFlag: FlagOption?

        var body: some View {
            FlagOptionPicker(
                selectedOption: $selectedFlag,
                options: FlagOption.flagContentCategories,
                title: "Create a tag for this content that other people in your network can see.",
                subtitle: "Select a tag for the content"
            )
            .onAppear {
                selectedFlag = FlagOption.flagContentCategories.first
            }
            .background(Color.appBg)
        }
    }
    return PreviewWrapper()
}
