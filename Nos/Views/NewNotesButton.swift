import SwiftUI

/// A button that should float above the notes when there are new notes available to display.
struct NewNotesButton: View {
    @FetchRequest var newNotes: FetchedResults<Event>
    var action: (() async -> Void)?

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
