//
//  AuthorListView.swift
//  Nos
//
//  Created by Martin Dutra on 29/3/23.
//

import Foundation
import SwiftUI

struct AuthorListView: View {
    
    @Binding var isPresented: Bool
    
    @Environment(\.managedObjectContext) private var viewContext

    @State private var authors: [Author]?

    @State private var filteredAuthors: [Author]?

    @StateObject private var searchTextObserver = SearchTextFieldObserver()
    
    @FocusState private var isSearching: Bool

    var didSelectGesture: ((Author) -> Void)?

    var body: some View {
        ScrollView(.vertical) {
            SearchBar(text: $searchTextObserver.text, isSearching: $isSearching)
                .readabilityPadding()
                .padding(.top, 10)
            LazyVStack {
                if let authors = filteredAuthors {
                    ForEach(authors) { author in
                        AuthorRow(author: author) {
                            didSelectGesture?(author)
                        }
                        .padding(.horizontal)
                    }
                } else {
                    ProgressView()
                }
            }
        }
        .background(Color.appBg)
        .nosNavigationBar(title: .mention)
        .onChange(of: searchTextObserver.debouncedText) { _, newValue in
            search(for: newValue)
        }
        .onAppear {
            isSearching = true
        }
        .disableAutocorrection(true)
        .task {
            refreshAuthors()
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(action: {
                    isPresented = false
                }, label: {
                    Localized.cancel.view
                        .foregroundColor(.primaryTxt)
                })
            }
        }
    }

    private func refreshAuthors() {
        let request = Author.allAuthorsWithNameOrDisplayNameRequest(muted: false)
        authors = try? viewContext.fetch(request)
        search(for: searchTextObserver.text)
    }

    private func search(for query: String) {
        guard !query.isEmpty else {
            filteredAuthors = authors
            return
        }
        let lowercasedQuery = query.lowercased()
        filteredAuthors = authors?.filter { author in
            if author.name?.lowercased().contains(lowercasedQuery) == true {
                return true
            }
            if author.displayName?.lowercased().contains(lowercasedQuery) == true {
                return true
            }
            if author.hexadecimalPublicKey?.lowercased().contains(lowercasedQuery) == true {
                return true
            }
            return false
        }
    }
}
