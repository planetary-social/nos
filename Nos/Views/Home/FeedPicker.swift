import CoreData
import Dependencies
import SwiftUI

/// A picker view used to pick which source a feed should show notes from.
struct FeedPicker: View {
    @Environment(FeedController.self) var feedController
    @Dependency(\.analytics) private var analytics
    
    var body: some View {
        BeveledContainerView {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(feedController.enabledSources, id: \.self) { source in
                            Button(action: {
                                switch source {
                                case .following:
                                    analytics.followFeedOpened()
                                case .relay:
                                    analytics.relayFeedOpened()
                                case .list:
                                    analytics.listFeedOpened()
                                }
                                
                                withAnimation(nil) {
                                    feedController.selectedSource = source
                                }
                            }, label: {
                                let isSelected = feedController.selectedSource == source
                                Text(source.displayName)
                                    .font(.system(size: 16, weight: isSelected ? .medium : .regular))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(isSelected ? Color.pickerBackgroundSelected : Color.clear)
                                    .foregroundStyle(isSelected ? Color.white : Color.secondaryTxt)
                                    .clipShape(Capsule())
                            })
                        }
                    }
                    .padding(.horizontal, 8)
                    .onChange(of: feedController.selectedSource) {
                        withAnimation {
                            proxy.scrollTo(feedController.selectedSource)
                        }
                    }
                }
                .frame(height: 40)
            }
        }
        .background(Color.cardBgTop)
    }
}
