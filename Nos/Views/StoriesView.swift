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
    
    @FetchRequest private var authors: FetchedResults<Author>
    
    @State private var selectedAuthor: Author
    @Binding private var cutoffDate: Date
    
    init(user: Author, cutoffDate: Binding<Date>, selectedAuthor: Author? = nil) {
        self.user = user
        self._cutoffDate = cutoffDate
        _authors = FetchRequest(fetchRequest: user.followedWithNewNotes(since: cutoffDate.wrappedValue))
        _selectedAuthor = .init(initialValue: selectedAuthor ?? Author())
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
        .task {
            if selectedAuthor == Author(), let firstAuthor = authors.first {
                selectedAuthor = firstAuthor
            }
        }
    }
    
    func showNextAuthor(from authors: FetchedResults<Author>) {
        guard let selectedAuthorIndex = authors.firstIndex(of: selectedAuthor) else {
            return
        }
        guard authors.endIndex - 1 > selectedAuthorIndex else {
            router.pop()
            return
        }
        let nextIndex = authors.index(after: selectedAuthorIndex)
        if let nextAuthor = authors[safe: nextIndex] {
            self.selectedAuthor = nextAuthor
        } else {
            router.pop()
            return
        }
    }
    
    func showPreviousAuthor(from authors: FetchedResults<Author>) {
        guard let selectedAuthorIndex = authors.firstIndex(of: selectedAuthor) else {
            return
        }
        guard authors.startIndex < selectedAuthorIndex else {
            router.pop()
            return
        }
        let previousIndex = authors.index(before: selectedAuthorIndex)
        if let previousAuthor = authors[safe: previousIndex] {
            selectedAuthor = previousAuthor
        } else {
            router.pop()
            return
        }
    }
}

struct HomeStoriesView_Previews: PreviewProvider {
    
    static var previewData = PreviewData()
    @State static var cutoffDate = Calendar.current.date(byAdding: .day, value: -14, to: .now)!
    
    static var previews: some View {
        StoriesView(user: previewData.currentUser.author!, cutoffDate: $cutoffDate)
            .inject(previewData: previewData)
    }
}
