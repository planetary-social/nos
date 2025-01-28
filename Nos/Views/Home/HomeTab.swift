import SwiftUI
import Inject

/// A styled tip view that contains the text provided.
///
/// Caution: As of iOS 18, TipKit does not allow styling of popover-style tips, so this
/// is a custom replication of TipKit's popover with custom styling. This is a bespoke
/// solution for the specific view it is in and will need to be modified to suit other views.
fileprivate struct PopoverTipView: View {
    let text: String
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                
                Image(systemName: "triangle.fill")
                    .resizable()
                    .foregroundStyle(Color.actionPrimaryGradientTop)
                    .frame(width: 20, height: 10)
                    .padding(.trailing, 23)
                    .offset(y: 4)
            }
            
            HStack {
                Spacer()
                
                HStack(alignment: .top) {
                    Text(text)
                        .font(.clarityBold(.headline))
                        .padding(.horizontal, 2)
                    
                    Image(systemName: "xmark")
                        .padding(.trailing, 6)
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(LinearGradient.horizontalAccentReversed)
                )
                .padding(.bottom, 4)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.tipShadow)
                )
                .frame(idealWidth: 320)
                
                Spacer()
                    .frame(width: 8)
            }
        }
    }
}

struct HomeTab: View {
    var user: Author
    
    @EnvironmentObject private var router: Router
    @ObserveInjection var inject
    @State private var feedTip = FeedSelectorTip()
    @State private var showFeedTip = false
    @State private var timer: Timer?
    @State private var scrollOffsetY: CGFloat = 0
    
    var body: some View {
        ZStack {
            NosNavigationStack(path: $router.homeFeedPath) {
                HomeFeedView(
                    user: user,
                    showFeedTip: $showFeedTip,
                    scrollOffsetY: $scrollOffsetY
                )
            }
            
            if showFeedTip {
                VStack {
                    Spacer()
                        .frame(height: 24)
                    
                    HStack {
                        Spacer()
                        
                        PopoverTipView(text: "Curate your feed with lists, custom feeds, and relays.")
                            .onTapGesture {
                                withAnimation {
                                    showFeedTip.toggle()
                                }
                            }
                    }
                    Spacer()
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            if !feedTip.hasShown {
                timer = Timer.scheduledTimer(withTimeInterval: FeedSelectorTip.maximumDelay, repeats: false) { _ in
                    showTip()
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
        .onChange(of: scrollOffsetY) {
            if scrollOffsetY > FeedSelectorTip.minimumScrollOffset {
                showTip()
            }
        }
        .enableInjection()
    }
    
    private func showTip() {
        guard !feedTip.hasShown else {
            return
        }
        
        withAnimation {
            showFeedTip = true
        }
        feedTip.hasShown = true
    }
}

struct HomeTab_Previews: PreviewProvider {
    
    static var previewData = PreviewData()
    
    static var previews: some View {
        NavigationView {
            HomeFeedView(
                user: previewData.currentUser.author!,
                showFeedTip: .constant(false),
                scrollOffsetY: .constant(0)
            )
            .inject(previewData: previewData)
        }
    }
}
