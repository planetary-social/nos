//
//  StoriesView.swift
//  Nos
//
//  Created by Matthew Lorentz on 3/23/23.
//

import SwiftUI

struct StoriesView: View {
    
    @ObservedObject var user: Author
    
    @FetchRequest private var authors: FetchedResults<Author>
    
    @State private var selectedAuthor: Author?
    @Binding private var cutoffDate: Date

    @Binding private var isPresented: Bool
    
    init(isPresented: Binding<Bool>, user: Author, cutoffDate: Binding<Date>) {
        self._isPresented = isPresented
        self.user = user
        self._cutoffDate = cutoffDate
        _authors = FetchRequest(fetchRequest: user.followedWithNewNotes(since: cutoffDate.wrappedValue))
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
    }
    
    func showNextAuthor(from authors: FetchedResults<Author>) {
        guard let selectedAuthor, let selectedAuthorIndex = authors.firstIndex(of: selectedAuthor) else {
            return
        }
        guard authors.endIndex - 1 > selectedAuthorIndex else {
            isPresented = false
            return
        }
        let nextIndex = authors.index(after: selectedAuthorIndex)
        self.selectedAuthor = authors[safe: nextIndex]
    }
    
    func showPreviousAuthor(from authors: FetchedResults<Author>) {
        guard let selectedAuthor, let selectedAuthorIndex = authors.firstIndex(of: selectedAuthor) else {
            return
        }
        guard authors.startIndex < selectedAuthorIndex else {
            isPresented = false
            return
        }
        let previousIndex = authors.index(before: selectedAuthorIndex)
        self.selectedAuthor = authors[safe: previousIndex]
    }
}

struct HomeStoriesView_Previews: PreviewProvider {
    
    static var previewData = PreviewData()
    @State static var cutoffDate = Calendar.current.date(byAdding: .day, value: -14, to: .now)!
    
    static var previews: some View {
        StoriesView(isPresented: .constant(true), user: previewData.currentUser.author!, cutoffDate: $cutoffDate)
            .inject(previewData: previewData)
    }
}
