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
    
    @State private var currentAuthor: Author?
    @State private var currentAuthorIndex: Int = 0
    
    init(user: Author) {
        self.user = user
        _authors = FetchRequest(fetchRequest: user.followsRequest())
        currentAuthor = user
    }
    
    var body: some View {
        VStack {
            // hack
            let _ = handleAuthorsChanged(to: authors)
            if let currentAuthor = currentAuthor {
                AuthorStoryView(
                    author: currentAuthor,
                    showPreviousAuthor: { self.showPreviousAuthor(from: self.authors) },
                    showNextAuthor: { self.showNextAuthor(from: self.authors) }
                )
            } else {
                Text("Hello, world")
            }
        }
        .background(Color.appBg)
        .nosNavigationBar(title: .stories)
    }
    
    func handleAuthorsChanged(to authors: FetchedResults<Author>) {
        Task {
            if authors.isEmpty {
                currentAuthor = nil
            } else if currentAuthor == nil {
                currentAuthor = authors.first
            }
        }
    }
    
    func showNextAuthor(from authors: FetchedResults<Author>) {
        if let currentAuthor,
           let currentAuthorIndex = authors.firstIndex(of: currentAuthor) {
            let nextAuthorIndex = authors.index(after: currentAuthorIndex)
            self.currentAuthor = authors[nextAuthorIndex]
        } else {
            currentAuthor = nil
        }
    }
    
    func showPreviousAuthor(from authors: FetchedResults<Author>) {
        if let currentAuthor,
           let currentAuthorIndex = authors.firstIndex(of: currentAuthor) {
            let nextAuthorIndex = authors.index(before: currentAuthorIndex)
            self.currentAuthor = authors[nextAuthorIndex]
        } else {
            currentAuthor = nil
        }
    }
}

struct HomeStoriesView_Previews: PreviewProvider {
    
    static var previewData = PreviewData()
    
    static var previews: some View {
        StoriesView(user: previewData.currentUser.author!)
            .inject(previewData: previewData)
    }
}
