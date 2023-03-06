//
//  DiscoverView.swift
//  Nos
//
//  Created by Matthew Lorentz on 2/24/23.
//

import SwiftUI

struct DiscoverView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @EnvironmentObject private var relayService: RelayService

    @FetchRequest(fetchRequest: Event.discoverFeedRequest(), animation: .default)
    private var events: FetchedResults<Event>
    
    @EnvironmentObject var router: Router
    
    @State var columns: Int = 2
    
    @Namespace private var animation
    
    @State private var subscriptionId: String = ""
    
    func refreshDiscover() {
        let filter = Filter(
            authorKeys: Array(Event.discoverTabUserIdToInfo.keys).compactMap {
                PublicKey(npub: $0)?.hex
            },
            kinds: [.text],
            limit: 100
            )
        subscriptionId = relayService.requestEventsFromAll(filter: filter)
    }
    
    var body: some View {
        NavigationStack(path: $router.path) {
            StaggeredGrid(list: events, columns: columns) { note in
                NoteButton(note: note, style: .golden)
                    .matchedGeometryEffect(id: note.identifier, in: animation)
            }
            .padding(.horizontal)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        columns += 1
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        columns = max(columns - 1, 1)
                    } label: {
                        Image(systemName: "minus")
                    }
                }
            }
            .animation(.easeInOut, value: columns)
            .refreshable {
                refreshDiscover()
            }
            .task {
                refreshDiscover()
            }
            .onDisappear {
                relayService.sendCloseToAll(subscriptions: [subscriptionId])
                subscriptionId = ""
            }
            .navigationDestination(for: Event.self) { note in
                RepliesView(note: note)
            }
            .navigationDestination(for: Author.self) { author in
                ProfileView(author: author)
            }
            .navigationDestination(for: AppView.Destination.self) { destination in
                if destination == AppView.Destination.settings {
                    SettingsView()
                }
            }
        }
    }
}

struct StaggeredGrid<Content: View, T: Identifiable, L: RandomAccessCollection<T>>: View where T: Hashable {
    
    var content: (T) -> Content
    
    var list: L
    
    var columns: Int
    var spacing: CGFloat
    
    init(list: L, columns: Int, spacing: CGFloat = 10, @ViewBuilder content: @escaping (T) -> Content) {
        self.content = content
        self.list = list
        self.spacing = spacing
        self.columns = columns
    }
    
    func setUpList() -> [[T]] {
        var gridArray: [[T]] = Array(repeating: [], count: columns)
        
        var currentIndex = 0
        
        for object in list {
            gridArray[currentIndex].append(object)
            
            if currentIndex == columns - 1 {
                currentIndex = 0
            } else {
                currentIndex += 1
            }
        }
        
        return gridArray
    }
    
    var body: some View {
        ScrollView(.vertical) {
            HStack(alignment: .top) {
                ForEach(setUpList(), id: \.self) { columnsData in
                    LazyVStack(spacing: spacing) {
                        ForEach(columnsData) { model in
                            content(model)
                        }
                    }
                }
            }
        }
    }
}

struct DiscoverView_Previews: PreviewProvider {
    
    static var persistenceController = PersistenceController.preview
    static var previewContext = persistenceController.container.viewContext
    static var relayService = RelayService(persistenceController: persistenceController)
    
    static var emptyPersistenceController = PersistenceController.empty
    static var emptyPreviewContext = emptyPersistenceController.container.viewContext
    static var emptyRelayService = RelayService(persistenceController: emptyPersistenceController)
    
    static var router = Router()
    
    static var shortNote: Event {
        let note = Event(context: previewContext)
        note.content = "Hello, world!"
        try! previewContext.save()
        return note
    }
    
    static var longNote: Event {
        let note = Event(context: previewContext)
        note.content = .loremIpsum(5)
        return note
    }
    
    static var previews: some View {
        DiscoverView()
            .environment(\.managedObjectContext, previewContext)
            .environmentObject(relayService)
            .environmentObject(router)
    }
}
