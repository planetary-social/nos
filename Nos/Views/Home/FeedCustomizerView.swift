import Dependencies
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
    
    @Dependency(\.analytics) private var analytics
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
                            if !feedController.listRowItems.isEmpty {
                                SecondaryActionButton(
                                    "manageYourLists",
                                    font: .clarity(.semibold, textStyle: .footnote),
                                    image: Image(systemName: "slider.horizontal.3")
                                ) {
                                    analytics.feedCustomizerClosed()
                                    shouldNavigateToLists = true
                                }
                            }
                        }
                        .padding()
                    },
                    noContent: {
                        VStack(spacing: 28) {
                            Text("noLists")
                                .font(.clarity(.medium))
                                .multilineTextAlignment(.center)
                            SecondaryActionButton(
                                "createYourFirstList",
                                font: .clarity(.semibold, textStyle: .footnote)
                            ) {
                                analytics.feedCustomizerClosed()
                                shouldNavigateToLists = true
                            }
                        }
                        .padding(24)
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
                            analytics.feedCustomizerClosed()
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
