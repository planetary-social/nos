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
            "lists"
        case .relays:
            "relays"
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
    @Binding var shouldNavigateToLists: Bool
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
                    headerText: Text("addListsDescription"),
                    items: feedController.listRowItems,
                    footer: {
                        Group {
                            if feedController.listRowItems.isEmpty {
                                Group {
                                    Text("Create your own lists on ") +
                                    Text("Listr ")
                                        .foregroundStyle(Color.accent) +
                                    Text(Image(systemName: "link"))
                                        .foregroundStyle(Color.accent)
                                }
                                .onTapGesture {
                                    if let url = URL(string: "https://listr.lol/feed") {
                                        UIApplication.shared.open(url)
                                    }
                                }
                            } else {
                                SecondaryActionButton(
                                    "manageYourLists",
                                    font: .clarity(.semibold, textStyle: .footnote),
                                    image: Image(systemName: "slider.horizontal.3")
                                ) {
                                    shouldNavigateToLists = true
                                }
                            }
                        }
                        .padding()
                    },
                    noContent: {
                        Text("noLists")
                    }
                )
            } else {
                FeedSourceToggleView(
                    author: author,
                    headerText: Text("selectRelaysDescription"),
                    items: feedController.relayRowItems,
                    footer: {
                        Group {
                            Text("Manage these on the ") +
                            (Text("relays")
                                .foregroundStyle(Color.accent)) +
                            Text(" screen")
                        }
                        .padding()
                        .onTapGesture {
                            shouldNavigateToRelays = true
                        }
                    },
                    noContent: {
                        Text("noRelays")
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
