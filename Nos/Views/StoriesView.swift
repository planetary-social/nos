//
//  StoriesView.swift
//  Nos
//
//  Created by Matthew Lorentz on 3/23/23.
//

import SwiftUI

struct StoriesDestination: Hashable {
    var author: Author?
}

struct StoriesView: View {

    @ObservedObject var user: Author

    @EnvironmentObject var router: Router

    private var authors: FetchedResults<Author>

    @Binding var selectedAuthorInStories: Author?

    @State private var selectedAuthor: Author
    @Binding private var cutoffDate: Date
    
    init(
        user: Author,
        cutoffDate: Binding<Date>,
        authors: FetchedResults<Author>,
        selectedAuthor: Binding<Author?>
    ) {
        self.user = user
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
        .background(Color.appBg)
        .nosNavigationBar(title: .stories)
        .task(id: selectedAuthorInStories) {
            if let selectedAuthorInStories {
                selectedAuthor = selectedAuthorInStories
            } else if let firstAuthor = authors.first {
                selectedAuthor = firstAuthor
            }
        }
    }
    
    func showNextAuthor(from authors: FetchedResults<Author>) {
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
        } else {
            selectedAuthorInStories = nil
            return
        }
    }
    
    func showPreviousAuthor(from authors: FetchedResults<Author>) {
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
        } else {
            selectedAuthorInStories = nil
            return
        }
    }
}
