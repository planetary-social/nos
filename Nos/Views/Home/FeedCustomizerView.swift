import SwiftUI

enum FeedTab: String {
    case lists
    case relays
}

extension FeedTab: NosSegmentedPickerItem {
    var id: String {
        rawValue
    }
    
    var titleKey: LocalizedStringKey {
        switch self {
        case .lists:
            "Lists"
        case .relays:
            "Relays"
        }
    }
    
    var image: Image {
        switch self {
        case .lists:
            Image(systemName: "person.2")
        case .relays:
            Image(systemName: "antenna.radiowaves.left.and.right")
        }
    }
}

struct FeedCustomizerView: View {
    
    @Environment(FeedController.self) var feedController
    let author: Author
    @Binding var shouldNavigateToRelays: Bool
    
    @AppStorage("selectedFeedTogglesTab") private var selectedTab = FeedTab.lists
    
    var body: some View {
        VStack(spacing: 0) {
            BeveledContainerView {
                NosSegmentedPicker(
                    items: [FeedTab.lists, FeedTab.relays],
                    selectedItem: $selectedTab
                )
            }
            
            if selectedTab == .lists {
                FeedSourceToggleView(
                    author: author,
                    headerText: Text("Add lists to your feed to filter by topic."),
                    items: feedController.listRowItems,
                    footer: {
                        Group {
                            Text("Create your own lists on ") +
                            Text("Listr ")
                                .foregroundStyle(Color.accent) +
                            Text(Image(systemName: "link"))
                                .foregroundStyle(Color.accent)
                        }
                        .padding()
                        .onTapGesture {
                            if let url = URL(string: "https://listr.lol/feed") {
                                UIApplication.shared.open(url)
                            }
                        }
                    },
                    noContent: {
                        Text("It doesn’t look like you have created any lists.")    // TODO: localize
                    }
                )
            } else {
                FeedSourceToggleView(
                    author: author,
                    headerText: Text("Select relays to show on your feed."),    // TODO: localize
                    items: feedController.relayRowItems,
                    footer: {
                        Group {
                            Text("Manage these on the ") +
                            (Text("Relays")
                                .foregroundStyle(Color.accent)) +
                            Text(" screen")
                        }
                        .padding()
                        .onTapGesture {
                            shouldNavigateToRelays = true
                        }
                    },
                    noContent: {
                        Text("It doesn’t look like you have any relays.")   // TODO: localize
                    }
                )
            }
        }
        .background(
            Rectangle()
                .foregroundStyle(LinearGradient.cardBackground)
                .cornerRadius(20, corners: [.bottomLeft, .bottomRight])
                .shadow(radius: 15, y: 10)
        )
        .readabilityPadding()
        .frame(height: 400)
    }
}
