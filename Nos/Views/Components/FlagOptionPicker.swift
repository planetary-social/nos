import SwiftUI
/// Displays a list of selectable flag options
struct FlagOptionPicker: View {
    @Binding private var selectedOption: FlagOption?
    var options: [FlagOption]
    var title: String
    var subtitle: String?

    init(
        selectedOption: Binding<FlagOption?>,
        options: [FlagOption],
        title: String,
        subtitle: String?
    ) {
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
    }

    private var flagOptionsListView: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(options) { flag in
                FlagPickerRow(
                    flag: flag,
                    selection: $selectedOption
                )
                BeveledSeparator()
            }
        }
        .background(LinearGradient.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .mimicCardButtonStyle()
    }
}

/// A single row for a single flag option
private struct FlagPickerRow: View {
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
            VStack(alignment: .leading) {
                flagContent
                if let info = flag.info, flag.id == selection?.id {
                    infoBox(text: info)
                }
            }
        }
    }

    private var radioButton: some View {
        Button {
            selection = flag
        } label: {
            NosRadioButton(isSelected: isSelected)
        }
    }

    /// Displays the content of a flag option.
    /// Shows the title of the flag option and its description (if available).
    private var flagContent: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(flag.title)
                    .foregroundColor(.primaryTxt)
                    .font(.clarity(.regular))

                if let description = flag.description {
                    Text(description)
                        .foregroundColor(.secondaryTxt)
                        .font(.clarity(.regular, textStyle: .footnote))
                        .lineSpacing(8)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true) // this enables the text view expand as needed
                }
            }
            Spacer()

            NosRadioButton(isSelected: isSelected)
        }
    }

    /// Displays additional information about a flag option.
    private func infoBox(text: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.6))
                .blendMode(.softLight)
            VStack {
                Text(text)
                    .foregroundColor(.primaryTxt)
                    .font(.clarity(.regular, textStyle: .subheadline))
                    .multilineTextAlignment(.leading)
                    .padding(EdgeInsets(
                        top: 13,
                        leading: 12,
                        bottom: 18,
                        trailing: 13
                    ))
                .lineSpacing(8)

                Spacer()
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.top, 12)
    }
}

private struct HeaderView: View {
    var text: String
    var body: some View {
        Text(text)
            .lineSpacing(5)
            .foregroundColor(.primaryTxt)
            .font(.clarity(.bold))
            .padding(.bottom, 10)
    }
}

#Preview("Category Selection") {
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

#Preview("Send Selection") {
    struct PreviewWrapper: View {
        @State private var selectedFlag: FlagOption?

        var body: some View {
            FlagOptionPicker(
                selectedOption: $selectedFlag,
                options: FlagOption.flagContentSendCategories,
                title: "Send to Nos or Flag Publicly",
                subtitle: nil
            )
            .onAppear {
                selectedFlag = FlagOption.flagContentSendCategories.first
            }
            .background(Color.appBg)
        }
    }
    return PreviewWrapper()
}
