import SwiftUI
/// Displays a list of selectable flag options
struct FlagOptionPickerView: View {
    @Binding private var selectedFlag: FlagOption?
    var options: [FlagOption]
    var title: String
    var subTitle: String?

    init(selectedFlag: Binding<FlagOption?>, options: [FlagOption], title: String, subTitle: String?) {
        self._selectedFlag = selectedFlag
        self.options = options
        self.title = title
        self.subTitle = subTitle
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                HeaderView(text: title)

                if let subTitle = subTitle {
                    HeaderView(text: subTitle)
                }
                flagOptionsListView
            }
            .padding()
        }
        .background(Color.appBg)
    }

    private var flagOptionsListView: some View {
        VStack(alignment: .leading) {
            ForEach(options) { flag in
                FlagPickerRow(flag: flag, selection: $selectedFlag)
                BeveledSeparator()
            }
        }
        .background(
            LinearGradient(
                colors: [Color.cardBgTop, Color.cardBgBottom],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 15))
    }
}

/// A single row  for a single flag option
struct FlagPickerRow: View {
    var flag: FlagOption
    @Binding var selection: FlagOption?

    var isSelected: Bool {
        selection?.id == flag.id
    }

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 8) {
                Text(flag.title)
                    .foregroundColor(.primaryTxt)
                    .font(.clarity(.regular))

                if let description = flag.description {
                    Text(description)
                        .foregroundColor(.secondaryTxt)
                        .font(.clarity(.regular, textStyle: .footnote))
                        .lineSpacing(8)
                }
            }

            Spacer()

            Button {
                selection = flag
            } label: {
                NosRadioButtonView(isSelected: isSelected)
            }
        }
        .padding(12)
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

struct FlagOptionPickerView_Previews: PreviewProvider {
    struct PreviewWrapper: View {
        @State private var selectedFlag: FlagOption?

        var body: some View {
            FlagOptionPickerView(
                selectedFlag: $selectedFlag,
                options: FlagOption.flagContentCategories,
                title: "Create a tag for this content that other people in your network can see.",
                subTitle: "Select a tag for the content"
            )
            .onAppear {
                selectedFlag = FlagOption.flagContentCategories.first
            }
            .background(Color.appBg)
        }
    }

    static var previews: some View {
        PreviewWrapper()
    }
}
