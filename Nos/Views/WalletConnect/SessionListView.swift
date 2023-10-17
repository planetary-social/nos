//
//  SessionListView.swift
//  DAppExample
//
//  Created by Marcel Salej on 02/10/2023.
//

import SwiftUI

struct SessionListView: View {

    @ObservedObject private var viewModel: SessionListViewModel = SessionListViewModel()

    var body: some View {
        VStack {
            List {
                ForEach($viewModel.sessionListItems, id: \.self) { sessionItem in
                    VStack {
                        HStack {
                            Text("Topic:")
                                .font(.system(size: 14, weight: .semibold))
                            Text("\(sessionItem.topic.wrappedValue)")
                                .font(Font.system(size: 12, weight: .light))
                                .foregroundStyle(.black)
                        }
                        HStack {
                            Text("Namespaces:")
                                .font(.system(size: 14, weight: .semibold))
                            Text("\(sessionItem.namespaces.wrappedValue)")
                                .font(Font.system(size: 12, weight: .light))
                                .foregroundStyle(.black)
                            Spacer()
                        }
                        HStack {
                            Text("Peer:")
                                .font(.system(size: 14, weight: .semibold))
                            Text("\(sessionItem.peer.wrappedValue)")
                                .font(Font.system(size: 12, weight: .light))
                                .foregroundStyle(.black)
                            Spacer()
                        }
                    }
                }
                .onDelete(perform: delete)
            }
        }.onAppear {
            viewModel.generateList()
        }
        .navigationTitle("Opened sessions")
        .toolbar(content: {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    Task {
                        try? await viewModel.deleteAllSessions()
                    }
                }, label: {
                    Text("Delete all")
                })
            }
        })
    }

    func delete(at offsets: IndexSet) {
        for index in offsets {
            print("Deleting cell: \(index)")
            if index < viewModel.sessionListItems.count {
                Task {
                    let item = viewModel.sessionListItems[index]
                    try await viewModel.deleteSession(topic: item.topic)
                }
            }
        }
    }
}
