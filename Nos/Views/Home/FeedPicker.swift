import CoreData
import SwiftUI

/// The source to be used for a feed of notes.
enum FeedSource: Hashable, Equatable {
    case following
    case relay(String)
    case list(String)
    
    var displayName: String {
        switch self {
        case .following: String(localized: "following")
        case .relay(let name), .list(let name): name
        }
    }
    
    static func == (lhs: FeedSource, rhs: FeedSource) -> Bool {
        switch (lhs, rhs) {
        case (.following, .following): true
        case (.relay(let name1), .relay(let name2)): name1 == name2
        case (.list(let name1), .list(let name2)): name1 == name2
        default: false
        }
    }
}

/// A picker view used to pick which source a feed should show notes from.
struct FeedPicker: View {
    @Binding var selectedSource: FeedSource
    
    @FetchRequest var relays: FetchedResults<Relay>
    
    init(author: Author, selectedSource: Binding<FeedSource>) {
        _selectedSource = selectedSource
        _relays = FetchRequest(fetchRequest: Relay.relays(for: author))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HorizontalLine(color: .buttonBevelBottom)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(allSources, id: \.self) { source in
                        Button(action: {
                            withAnimation(nil) {
                                selectedSource = source
                            }
                        }, label: {
                            Text(source.displayName)
                                .font(.system(size: 16, weight: selectedSource == source ? .medium : .regular))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(selectedSource == source ? Color.pickerBackgroundSelected : Color.clear)
                                .foregroundStyle(selectedSource == source ? Color.white : Color.secondaryTxt)
                                .clipShape(Capsule())
                        })
                    }
                }
                .padding(.horizontal, 8)
            }
            .frame(height: 40)
            
            HorizontalLine(color: .panelBevelBottom, height: 1 / UIScreen.main.scale)
            
            HorizontalLine(color: .black, height: 1 / UIScreen.main.scale)
        }
        .background(Color.cardBgTop)
    }
    
    private var allSources: [FeedSource] {
        var sources = [FeedSource]()
        sources.append(.following)
        sources.append(contentsOf: relays.map { FeedSource.relay($0.host!) })
        // TODO: Add lists
        return sources
    }
}
