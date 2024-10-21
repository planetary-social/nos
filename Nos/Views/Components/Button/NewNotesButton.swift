import SwiftUI

/// A button that should float above the notes when there are new notes available to display.
struct NewNotesButton: View {
    /// New notes that have appeared.
    @FetchRequest var newNotes: FetchedResults<Event>

    /// The action to perform when the user taps this button.
    var action: (() async -> Void)?

    /// Initializes a new notes button with the given fetch request.
    /// When the given fetch request returns non-empty results, the button appears.
    /// - Parameter fetchRequest: The fetch request that determines whether there are new notes to display.
    init(fetchRequest: FetchRequest<Event>, action: @escaping () async -> Void) {
        _newNotes = fetchRequest
        self.action = action
    }

    var body: some View {
        if newNotes.isEmpty {
            EmptyView()
        } else {
            VStack {
                SecondaryActionButton(
                    "newNotesAvailable",
                    font: .clarity(.semibold, textStyle: .footnote),
                    action: action
                )
                Spacer()
            }
            .padding(8)
        }
    }
}
