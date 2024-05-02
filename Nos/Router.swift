import SwiftUI
import Combine
import CoreData
import Logger
import Dependencies

// Manages the app's navigation state.
@MainActor class Router: ObservableObject {

    @Published var homeFeedPath = NavigationPath()
    @Published var discoverPath = NavigationPath()
    @Published var notificationsPath = NavigationPath()
    @Published var profilePath = NavigationPath()
    @Published var sideMenuPath = NavigationPath()
    @Published var selectedTab = AppDestination.home
    @Published var isLoading = false
    @Dependency(\.persistenceController) private var persistenceController
    @Dependency(\.relayService) private var relayService

    var currentPath: Binding<NavigationPath> {
        if sideMenuOpened {
            return Binding(get: { self.sideMenuPath }, set: { self.sideMenuPath = $0 })
        }

        return path(for: selectedTab)
    }

    @Published private(set) var sideMenuOpened = false

    func toggleSideMenu() {
        withAnimation(.easeIn(duration: 0.2)) {
            sideMenuOpened.toggle()
        }
    }

    func closeSideMenu() {
        withAnimation(.easeIn(duration: 0.2)) {
            sideMenuOpened = false
        }
    }

    /// Pushes the given destination item onto the current NavigationPath.
    func push<D: Hashable>(_ destination: D) {
        currentPath.wrappedValue.append(destination)
    }

    func pop() {
        guard !currentPath.wrappedValue.isEmpty else { return }
        currentPath.wrappedValue.removeLast()
    }

    func openOSSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    func showNewNoteView(contents: String?) {
        selectedTab = .newNote(contents)
    }

    func consecutiveTaps(on tab: AppDestination) -> AnyPublisher<Void, Never> {
        $selectedTab
            .scan((previous: nil, current: selectedTab)) { previousPair, current in
                (previous: previousPair.current, current: current)
            }
            .filter {
                $0.previous == $0.current
            }
            .compactMap {
                $0.current == tab ? Void() : nil
            }
            .eraseToAnyPublisher()
    }

    func path(for destination: AppDestination) -> Binding<NavigationPath> {
        switch destination {
        case .home:
            return Binding(get: { self.homeFeedPath }, set: { self.homeFeedPath = $0 })
        case .discover:
            return Binding(get: { self.discoverPath }, set: { self.discoverPath = $0 })
        case .newNote:
            return Binding(get: { self.homeFeedPath }, set: { self.homeFeedPath = $0 })
        case .notifications:
            return Binding(get: { self.notificationsPath }, set: { self.notificationsPath = $0 })
        case .profile:
            return Binding(get: { self.profilePath }, set: { self.profilePath = $0 })
        }
    }
}

extension Router {

    nonisolated func open(url: URL, with context: NSManagedObjectContext) {
        let link = url.absoluteString
        let identifier = String(link[link.index(after: link.startIndex)...])

        Task { @MainActor in
            do {
                // handle mentions. mention link will be prefixed with "@"
                // followed by the hex format pubkey of the mentioned author
                if link.hasPrefix("@") {
                    if identifier.isValidHexadecimal {
                        try handleHexadecimalPublicKey(identifier)
                    } else {
                        try await handleNIP05Link(identifier)
                    }
                } else if link.hasPrefix("%") {
                    push(try Event.findOrCreateStubBy(id: identifier, context: persistenceController.viewContext))
                } else if url.scheme == "http" || url.scheme == "https" {
                    push(url)
                } else {
                    await UIApplication.shared.open(url)
                }
            } catch {
                Log.optional(error)
            }
        }
    }

    public func handleHexadecimalPublicKey(_ hex: String) throws {
        push(
            try Author.findOrCreate(
                by: hex,
                context: persistenceController.viewContext
            )
        )
    }

    private func handleNIP05Link(_ link: String) async throws {
        isLoading = true
        let npub = await relayService
            .retrievePublicKeyFromUsername(link)?
            .trimmingCharacters(
                in: NSCharacterSet.whitespacesAndNewlines
            )
        isLoading = false
        if let npub, let publicKey = PublicKey.build(npub) {
            push(
                try Author.findOrCreate(
                    by: publicKey.hex,
                    context: persistenceController.viewContext
                )
            )
        } else if let url = URL(string: "mailto:\(link)") {
            await UIApplication.shared.open(url)
        } else {
            Log.debug("Couldn't open \(link)")
        }
    }
}
