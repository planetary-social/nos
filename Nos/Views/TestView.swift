//
//  TestView.swift
//  Nos
//
//  Created by Martin Dutra on 25/9/23.
//

import SwiftUI

struct TestView: View {
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
        TabView {

        }
        .tabViewStyle(.page)
    }
}
