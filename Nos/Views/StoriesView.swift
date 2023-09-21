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
    
    @State private var currentAuthorIndex: Int = 0
    
    init(user: Author) {
        self.user = user
        _authors = FetchRequest(fetchRequest: user.followsRequest())
    }
    
    var body: some View {
        VStack {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(authors) { author in
                        Button { 
                            if let index = authors.firstIndex(of: author) {
                                currentAuthorIndex = index
                            }
                        } label: { 
                            AvatarView(imageUrl: author.profilePhotoURL, size: 54)
                                .padding(7)
                        }
                    }
                }
            }
            if let currentAuthor = authors[safe: currentAuthorIndex] {
                AuthorStoryView(
                    author: currentAuthor,
                    showPreviousAuthor: { self.showPreviousAuthor(from: self.authors) },
                    showNextAuthor: { self.showNextAuthor(from: self.authors) }
                )
                .id(currentAuthorIndex) // TODO: Why doesn't it work without this!?
            } else {
                Text("Hello, world")
            }
        }
        .background(Color.appBg)
        .nosNavigationBar(title: .stories)
    }
    
    func showNextAuthor(from authors: FetchedResults<Author>) {
        guard currentAuthorIndex < authors.count else { return }
        let nextAuthorIndex = authors.index(after: currentAuthorIndex)
        currentAuthorIndex = nextAuthorIndex
    }
    
    func showPreviousAuthor(from authors: FetchedResults<Author>) {
        guard currentAuthorIndex > 0 else { return }
        let previousAuthorIndex = authors.index(before: currentAuthorIndex)
        currentAuthorIndex = previousAuthorIndex
    }
}

struct HomeStoriesView_Previews: PreviewProvider {
    
    static var previewData = PreviewData()
    
    static var previews: some View {
        StoriesView(user: previewData.currentUser.author!)
            .inject(previewData: previewData)
    }
}
