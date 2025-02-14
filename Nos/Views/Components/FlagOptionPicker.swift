import SwiftUI

/// Displays a list of selectable flag options
struct FlagOptionPicker: View {
    /// The previous selection made by the user, used for displaying information related to changes in selection.
    /// A picker can have a previous selection or not.
    @Binding var previousSelection: FlagOption?

    /// The currently selected flag option.
    @Binding private var currentSelection: FlagOption?

    /// The list of available flag options to choose from.
    let options: [FlagOption]

    /// The title displayed at the top of the picker.
    let title: String

    /// An optional subtitle that provides additional context for the picker.
    let subtitle: String?

    init(
        previousSelection: Binding<FlagOption?>,
        currentSelection: Binding<FlagOption?>,
        options: [FlagOption],
        title: String,
        subtitle: String?
    ) {
        self._previousSelection = previousSelection
        self._currentSelection = currentSelection
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

    /// Represents the list of flag options.
    /// Each option is displayed as a row, and when an option is selected, the current selection is updated.
    private var flagOptionsListView: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(options) { flag in
                FlagPickerRow(
                    flag: flag,
                    selection: $currentSelection, 
                    previousSelection: $previousSelection
                )
                BeveledSeparator()
            }
        }
        .background(LinearGradient.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .mimicCardButtonStyle()
    }
}

/// A single row view displaying a flag option in the flag picker.
/// Displays a flag option with its title and optional description.
///  It highlights the selected option and allows the user to tap and select a new option.
private struct FlagPickerRow: View {
    /// The flag option associated with this row.
    let flag: FlagOption

    /// The current flag selection.
    @Binding var selection: FlagOption?

    /// The previous flag selection.
    @Binding var previousSelection: FlagOption?

    /// A Boolean value that indicates whether the flag is currently selected.
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
                    let infoText = info(previousSelection?.title)
                    infoBox(text: infoText ?? "")
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
                    .font(.body)

                if let description = flag.description {
                    Text(description)
                        .foregroundColor(.secondaryTxt)
                        .font(.footnote)
                        .lineSpacing(8)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true) // this enables the text view expand as needed
                }
            }
            Spacer()

            NosRadioButton(isSelected: isSelected)
        }
    }

    /// Displays additional information about the selected flag option.
    /// - Parameter text: The informational text to be displayed inside the box.
    private func infoBox(text: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.6))
                .blendMode(.softLight)
            VStack {
                Text(text)
                    .foregroundColor(.primaryTxt)
                    .font(.subheadline)
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
            .font(.headline)
            .fontWeight(.semibold)
            .padding(.bottom, 10)
    }
}

#Preview("Flag Content Selection") {
    struct PreviewWrapper: View {
        @State private var flagCategories: [FlagOption] = []
        @State private var selectedFlag: FlagOption?
        let author = Author()

        var body: some View {
            FlagOptionPicker(
                previousSelection: $selectedFlag, 
                currentSelection: $selectedFlag,
                options: flagCategories,
                title: "Create a tag for this content that other people in your network can see.",
                subtitle: "Select a tag for the content"
            )
            .onAppear {
                flagCategories = FlagOption.createFlagCategories(for: .author(author))
                selectedFlag = flagCategories.first
            }
            .background(Color.appBg)
        }
    }
    return PreviewWrapper()
}

#Preview("Flag User Selection") {
    struct PreviewWrapper: View {
        @State private var flagCategories: [FlagOption] = []
        @State private var selectedOption: FlagOption?
        let event = Event()

        var body: some View {
            FlagOptionPicker(
                previousSelection: $selectedOption,
                currentSelection: $selectedOption,
                options: flagCategories,
                title: "Create a tag for this user that other people in your network can see.",
                subtitle: "Select a tag for the user"
            )
            .onAppear {
                flagCategories = FlagOption.createFlagCategories(for: .note(event))
                selectedOption = flagCategories.first
            }
            .background(Color.appBg)
        }
    }
    return PreviewWrapper()
}

#Preview("Send Selection") {
    struct PreviewWrapper: View {
        @State private var selectedOption: FlagOption?

        var body: some View {
            FlagOptionPicker(
                previousSelection: $selectedOption,
                currentSelection: $selectedOption,
                options: FlagOption.flagContentSendOptions,
                title: "Send to Nos or Flag Publicly",
                subtitle: nil
            )
            .onAppear {
                selectedOption = FlagOption.flagContentSendOptions.first
            }
            .background(Color.appBg)
        }
    }
    return PreviewWrapper()
}
