//
//  StoriesView.swift
//  Nos
//
//  Created by Matthew Lorentz on 3/23/23.
//

import SwiftUI
import Dependencies

/// Shows a list of authors with stories in a carousel
struct StoriesView: View {

    /// Authors to display
    private var authors: [Author]

    /// Author tapped in the Home Feed
    ///
    /// Used to highlight it when the view appears and to close the view (by setting it to null)
    @Binding private var selectedAuthorInStories: Author?

    /// Used to avoid re-selecting the tapped author in the Home Feed when navigating back to the Stories
    @State private var previousSelectedAuthorInStories: Author?

    /// Author currently highlighted
    @State private var selectedAuthor: Author

    @Binding private var cutoffDate: Date

    @ObservationIgnored @Dependency(\.analytics) private var analytics

    init(
        cutoffDate: Binding<Date>,
        authors: [Author],
        selectedAuthor: Binding<Author?>
    ) {
        self._cutoffDate = cutoffDate
        self.authors = authors
        _selectedAuthor = .init(initialValue: selectedAuthor.wrappedValue ?? Author())
        _selectedAuthorInStories = selectedAuthor
    }
    
    var body: some View {
        VStack {
            TabView(selection: $selectedAuthor) {
                ForEach(authors) { author in
                    AuthorStoryView(
                        author: author,
                        cutoffDate: $cutoffDate,
                        showPreviousAuthor: { self.showPreviousAuthor(from: self.authors) },
                        showNextAuthor: { self.showNextAuthor(from: self.authors) }
                    )
                    .tag(author)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .background(LinearGradient.storiesBackground)
        .nosNavigationBar(title: .localizable.stories)
        .readabilityPadding()
        .task(id: selectedAuthorInStories) {
            guard previousSelectedAuthorInStories != selectedAuthorInStories else {
                return
            }
            if let selectedAuthorInStories {
                selectedAuthor = selectedAuthorInStories
            } else if let firstAuthor = authors.first {
                selectedAuthor = firstAuthor
            }
            previousSelectedAuthorInStories = selectedAuthorInStories
        }
    }
    
    func showNextAuthor(from authors: [Author]) {
        guard let selectedAuthorIndex = authors.firstIndex(of: selectedAuthor) else {
            return
        }
        guard authors.endIndex - 1 > selectedAuthorIndex else {
            selectedAuthorInStories = nil
            return
        }
        let nextIndex = authors.index(after: selectedAuthorIndex)
        if let nextAuthor = authors[safe: nextIndex] {
            self.selectedAuthor = nextAuthor
            analytics.storiesSwitchedToNextUser()
        } else {
            selectedAuthorInStories = nil
            return
        }
    }
    
    func showPreviousAuthor(from authors: [Author]) {
        guard let selectedAuthorIndex = authors.firstIndex(of: selectedAuthor) else {
            return
        }
        guard authors.startIndex < selectedAuthorIndex else {
            selectedAuthorInStories = nil
            return
        }
        let previousIndex = authors.index(before: selectedAuthorIndex)
        if let previousAuthor = authors[safe: previousIndex] {
            selectedAuthor = previousAuthor
            analytics.storiesSwitchedToNextUser()
        } else {
            selectedAuthorInStories = nil
            return
        }
    }
}
