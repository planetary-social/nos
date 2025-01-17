import Dependencies
import SwiftUI

struct AuthorListDetailView: View {
    
    @Dependency(\.relayService) private var relayService
    @EnvironmentObject private var router: Router
    
    @ObservedObject var list: AuthorList
    
    /// Subscriptions for metadata requests from the relay service, keyed by author ID.
    @State private var subscriptions = [ObjectIdentifier: SubscriptionCancellable]()
    
    @State private var showingEditListInfo = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ListCircle()
                
                VStack(spacing: 3) {
                    Text(list.title ?? "")
                        .font(.headline.weight(.bold))
                        .multilineTextAlignment(.center)
                    
                    Text(String.localizedStringWithFormat(String(localized: "xUsers"), list.allAuthors.count))
                        .foregroundStyle(Color.secondaryTxt)
                        .font(.footnote)
                    
                    if let description = list.listDescription, !description.isEmpty {
                        Text(description)
                            .foregroundStyle(Color.secondaryTxt)
                            .font(.footnote)
                            .padding(.top, 8)
                    }
                }
            }
            .padding(.top, 24)
            
            LazyVStack {
                ForEach(list.allAuthors.sorted(by: { ($0.displayName ?? "") < ($1.displayName ?? "") })) { author in
                    AuthorObservationView(authorID: author.hexadecimalPublicKey) { author in
                        AuthorCard(author: author) {
                            router.push(author)
                        }
                        .padding(.horizontal, 13)
                        .padding(.top, 5)
                        .readabilityPadding()
                        .task {
                            subscriptions[author.id] =
                            await relayService.requestMetadata(
                                for: author.hexadecimalPublicKey,
                                since: author.lastUpdatedMetadata
                            )
                        }
                    }
                }
            }
            .padding(.vertical, 12)
        }
        .nosNavigationBar("")
        .background(Color.appBg)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("editListInfo") {
                        showingEditListInfo = true
                    }
                    Button("manageUsers") {
                        // TODO: Manage Users
                    }
                    Button("deleteList", role: .destructive) {
                        // TODO: Delete List
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(Color.secondaryTxt)
                        .fontWeight(.bold)
                        .padding(.vertical, 12)
                }
            }
        }
        .sheet(isPresented: $showingEditListInfo) {
            NavigationStack {
                EditAuthorListView(list: list)
            }
        }
    }
}
