import SwiftUI

/// A button that should float above the notes when there are new notes available to display.
struct NewNotesButton: View {
    /// New notes that have appeared since the last refresh date.
    @FetchRequest var newNotes: FetchedResults<Event>

    /// The action to perform when the user taps this button.
    var action: (() async -> Void)?

    
    /// Initializes a new notes button with the given values.
    /// - Parameters:
    ///   - user: The user whose home feed we're displaying.
    ///   - lastRefreshDate: The last time the view was refreshed.
    ///   - seenOn: The selected relay, if any.
    ///   - action: The action to perform when the user taps this button.
    init(user: Author, lastRefreshDate: Date, seenOn: Relay?, action: @escaping () async -> Void) {
        let request = Event.homeFeed(for: user, after: lastRefreshDate, seenOn: seenOn)
        _newNotes = FetchRequest(fetchRequest: request)
        self.action = action
    }

    var body: some View {
        if newNotes.isEmpty {
            EmptyView()
        } else {
            VStack {
                SecondaryActionButton(
                    title: .localizable.newNotesAvailable,
                    font: .clarity(.semibold, textStyle: .footnote),
                    action: action
                )
                Spacer()
            }
            .padding(8)
        }
    }
}
