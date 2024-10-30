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
    @Dependency(\.crashReporting) private var crashReporting

    /// The `NavigationPath` of the tab (or side menu) the user currently has open. 
    /// This has to be a two-way binding, but really the only things that should be modifying it are the `Router`
    /// or a `NavigationStack`. Don't mutate it directly outside this class.
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
    
    /// Pushes a view displaying the object wrapped in a `NosNavigationDestination`.
    func push(_ destination: NosNavigationDestination) {
        currentPath.wrappedValue.append(destination)
    }
    
    /// Pushes a detail view for the given note.
    func push(_ note: Event) {
        if let identifier = note.identifier {
            push(.note(.identifier(identifier)))
        } else if let replaceableIdentifier = note.replaceableIdentifier, let author = note.author {
            push(
                .note(
                    .replaceableIdentifier(replaceableID: replaceableIdentifier, author: author, kind: note.kind)
                )
            )
        } else {
            let debuggingDetails = """
            noteId: \(String(describing: note.identifier)) \n
            replaceableIdentifier: \(String(describing: note.replaceableIdentifier)) \n
            noteAuthor: \(String(describing: note.author))
            """

            crashReporting.report("Tried to push a note and it failed. Details: \n \(debuggingDetails)")
            assertionFailure("Tried to push a note and it failed. Details: \n \(debuggingDetails)")
        }
    }
    
    /// Pushes a detail view for the note with the given ID, creating one if needed.
    func pushNote(id: RawEventID) {
        do {
            let note = try Event.findOrCreateStubBy(id: id, context: persistenceController.viewContext)
            push(note)
        } catch {
            Log.optional(error)
            crashReporting.report(error)
        }
    }    
    
    /// Pushes a detail view for the event with the given replaceable ID and author, creating one if needed.
    func pushNote(replaceableID: RawReplaceableID, authorID: RawAuthorID, kind: Int64) {
        do {
            let note = try Event.findOrCreateStubBy(
                replaceableID: replaceableID, 
                authorID: authorID,
                kind: kind,
                context: persistenceController.viewContext
            )
            push(note)
        } catch {
            Log.optional(error)
            crashReporting.report(error)
        }
    }
    
    /// Pushes a profile view for the given author.
    func push(_ author: Author) {
        push(.author(author.hexadecimalPublicKey))
    }
    
    /// Pushes a profile view for the author with the given ID, creating one if needed.
    func pushAuthor(id: RawAuthorID) {
        do {
            let author = try Author.findOrCreate(by: id, context: persistenceController.viewContext)
            push(author)
        } catch {
            Log.optional(error)
            crashReporting.report(error)
        }
    }
    
    /// Pushes a web view for the given url.
    func push(_ url: URL) {
        push(.url(url))
    }

    func pop() {
        guard !currentPath.wrappedValue.isEmpty else { return }
        currentPath.wrappedValue.removeLast()
    }

    func openOSSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    func showNoteComposer(contents: String?) {
        selectedTab = .noteComposer(contents)
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
        case .noteComposer:
            return Binding(get: { self.homeFeedPath }, set: { self.homeFeedPath = $0 })
        case .notifications:
            return Binding(get: { self.notificationsPath }, set: { self.notificationsPath = $0 })
        case .profile:
            return Binding(get: { self.profilePath }, set: { self.profilePath = $0 })
        case .myStreams:
            return Binding(get: { self.profilePath }, set: { self.profilePath = $0 })
        }
    }
}

extension Router {

    nonisolated func open(url: URL) {
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
                    pushNote(id: identifier)
                } else if link.hasPrefix("$") {
                    let separator = ";"
                    let parts = identifier.split(separator: separator).map { String($0) }
                    guard parts.count >= 3,
                        let kindString = parts.last,
                        let kind = Int64(kindString),
                        let authorID = parts.dropLast().last else {
                        Log.debug("Something went wrong parsing the replaceableID and author from the naddr link")
                        return
                    }
                    let replaceableID = parts.dropLast(2).joined(separator: separator)
                    pushNote(replaceableID: replaceableID, authorID: authorID, kind: kind)
                } else if let scheme = url.scheme,
                    DeepLinkService.supportedURLSchemes.contains(scheme) {
                    DeepLinkService.handle(url, router: self)
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
        pushAuthor(id: hex)
    }

    private func handleNIP05Link(_ link: String) async throws {
        isLoading = true
        let npub = await relayService
            .retrievePublicKeyFromUsername(link)?
            .trimmingCharacters(
                in: NSCharacterSet.whitespacesAndNewlines
            )
        isLoading = false
        if let npub, let publicKey = PublicKey.build(npubOrHex: npub) {
            pushAuthor(id: publicKey.hex)
        } else if let url = URL(string: "mailto:\(link)") {
            await UIApplication.shared.open(url)
        } else {
            Log.debug("Couldn't open \(link)")
        }
    }
}
