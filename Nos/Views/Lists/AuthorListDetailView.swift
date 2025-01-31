import Dependencies
import SwiftUI

struct AuthorListDetailView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Dependency(\.relayService) private var relayService
    @Environment(CurrentUser.self) private var currentUser
    @EnvironmentObject private var router: Router
    
    @ObservedObject var list: AuthorList
    
    /// Subscriptions for metadata requests from the relay service, keyed by author ID.
    @State private var subscriptions = [ObjectIdentifier: SubscriptionCancellable]()
    
    @State private var showingEditListInfo = false
    @State private var showingManageUsers = false

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
                        AuthorCard(
                            author: author,
                            avatarOverlayView: { EmptyView() },
                            onTap: {
                                router.push(author)
                            }
                        )
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
                .padding(.vertical, 12)
            }
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
                        showingManageUsers = true
                    }
                    Button("deleteList", role: .destructive) {
                        deleteList()
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
        .sheet(isPresented: $showingManageUsers) {
            NavigationStack {
                AuthorListManageUsersView(list: list)
            }
        }
    }
    
    private func deleteList() {
        guard let replaceableID = list.replaceableIdentifier else {
            return
        }
        
        Task {
            await currentUser.publishDelete(for: replaceableID, kind: list.kind)
            dismiss()
        }
    }
}
