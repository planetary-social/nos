//
//  DiscoverGrid.swift
//  Nos
//
//  Created by Matthew Lorentz on 3/16/23.
//

import SwiftUI

struct DiscoverGrid: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(fetchRequest: Event.emptyDiscoverRequest()) var events: FetchedResults<Event>
    @ObservedObject var searchModel: SearchModel
    
    @Binding var columns: Int
    @State private var gridSize: CGSize = .zero {
        didSet {
            // Initialize columns based on width of the grid
            if columns == 0, gridSize.width > 0 {
                columns = Int(floor(gridSize.width / 172))
            }
        }
    }
    
    @Namespace private var animation

    init(predicate: NSPredicate, searchModel: SearchModel, columns: Binding<Int>) {
        let fetchRequest = Event.emptyDiscoverRequest()
        fetchRequest.predicate = predicate
        fetchRequest.fetchLimit = 1000
        _events = FetchRequest(fetchRequest: fetchRequest)
        _columns = columns
        self.searchModel = searchModel
    }
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                Group {
                    if searchModel.query.isEmpty {
                        StaggeredGrid(list: events, columns: columns) { note in
                            NoteButton(note: note, style: .golden)
                                .matchedGeometryEffect(id: note.identifier, in: animation)
                        }
                    } else {
                        // Search results
                        StaggeredGrid(list: searchModel.authorSuggestions, columns: columns) { author in
                            AuthorCard(author: author)
                                .matchedGeometryEffect(id: author.hexadecimalPublicKey, in: animation)
                        }
                    }
                }
                .preference(key: SizePreferenceKey.self, value: geometry.size)
            }
            .onPreferenceChange(SizePreferenceKey.self) { preference in
                gridSize = preference
            }
        }
    }
}
