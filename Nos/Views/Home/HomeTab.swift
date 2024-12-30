import Dependencies
import SwiftUI

/// A styled tip view that contains the text provided.
///
/// Caution: As of iOS 18, TipKit does not allow styling of popover-style tips, so this
/// is a custom replication of TipKit's popover with custom styling. This is a bespoke
/// solution for the specific view it is in and will need to be modified to suit other views.
struct PopoverTipView: View {
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

let hasShownFeedTip = "com.verse.nos.Home.hasShownFeedTip"

struct HomeTab: View {
    @Dependency(\.userDefaults) private var userDefaults
    
    @ObservedObject var user: Author
    
    @EnvironmentObject private var router: Router
    
    @State private var showFeedTip = false
    
    var body: some View {
        ZStack {
            NosNavigationStack(path: $router.homeFeedPath) {
                HomeFeedView(user: user, showFeedTip: $showFeedTip)
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
            if !userDefaults.bool(forKey: hasShownFeedTip) {
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                    withAnimation {
                        showFeedTip = true
                    }
                }
                
                userDefaults.set(true, forKey: hasShownFeedTip)
            }
        }
    }
}

struct HomeTab_Previews: PreviewProvider {
    
    static var previewData = PreviewData()
    
    static var previews: some View {
        NavigationView {
            HomeFeedView(user: previewData.currentUser.author!, showFeedTip: .constant(false))
                .inject(previewData: previewData)
        }
    }
}
