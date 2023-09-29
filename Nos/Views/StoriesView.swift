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
    @State private var scrollViewProxy: ScrollViewProxy?
    @Binding private var cutoffDate: Date
    
    init(user: Author, cutoffDate: Binding<Date>) {
        self.user = user
        self._cutoffDate = cutoffDate
        _authors = FetchRequest(fetchRequest: user.followedWithNewNotes(since: cutoffDate.wrappedValue))
    }
    
    var body: some View {
        VStack {
            ScrollView(.horizontal) {
                ScrollViewReader { proxy in
                    HStack {
                        ForEach(authors) { author in
                            let index = authors.firstIndex(of: author)
                            Button { 
                                if let index {
                                    currentAuthorIndex = index
                                }
                            } label: { 
                                let avatar = AvatarView(imageUrl: author.profilePhotoURL, size: 54)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 15)
                                
                                if let index, index == currentAuthorIndex {
                                    avatar
                                        .background(
                                            Circle()
                                                .stroke(LinearGradient.diagonalAccent, lineWidth: 3)
                                                .frame(width: 58, height: 58)
                                        )
                                } else {
                                    avatar
                                }
                            }
                            .id(index)
                            .onAppear {
                                scrollViewProxy = proxy
                            }
                        }
                    }
                }
            }
            if let currentAuthor = authors[safe: currentAuthorIndex] {
                AuthorStoryView(
                    author: currentAuthor,
                    cutoffDate: $cutoffDate,
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
        scrollViewProxy?.scrollTo(currentAuthorIndex)
    }
    
    func showPreviousAuthor(from authors: FetchedResults<Author>) {
        guard currentAuthorIndex > 0 else { return }
        let previousAuthorIndex = authors.index(before: currentAuthorIndex)
        currentAuthorIndex = previousAuthorIndex
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
