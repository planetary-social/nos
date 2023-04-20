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

    init(predicate: NSPredicate, columns: Binding<Int>) {
        let fetchRequest = Event.emptyDiscoverRequest()
        fetchRequest.predicate = predicate
        fetchRequest.fetchLimit = 1000
        _events = FetchRequest(fetchRequest: fetchRequest)
        _columns = columns
    }
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                StaggeredGrid(list: events, columns: columns) { note in
                    NoteButton(note: note, style: .golden)
                        .matchedGeometryEffect(id: note.identifier, in: animation)
                }
                
                .preference(key: SizePreferenceKey.self, value: geometry.size)
            }
            .onPreferenceChange(SizePreferenceKey.self) { preference in
                gridSize = preference
            }
        }
    }
}
