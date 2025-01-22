import Logger
import SwiftUI

/// Displays a search bar and user results. Allows the user to add or remove users
/// from an existing ``AuthorList`` and while creating a new one.
struct AuthorListManageUsersView: View {
    
    private enum Mode {
        case create(title: String, description: String?)
        case update(list: AuthorList)
        
        var buttonTitleKey: LocalizedStringKey {
            switch self {
            case .create:
                "save"
            case .update:
                "done"
            }
        }
    }
    
    @Environment(\.dismiss) private var dismiss
    @Environment(RelayService.self) private var relayService
    @Environment(CurrentUser.self) private var currentUser
    @Environment(\.managedObjectContext) private var viewContext
    @State private var authors: Set<Author>
    
    private var mode: Mode
    
    /// An action that runs after successfully saving an ``AuthorList``.
    ///
    /// Leaving the value nil will cause the Environment's `dismiss()` to be called, which may appear
    /// as a modal dismissal or a navigational pop depending on the presentation context.
    private let onSave: (() -> Void)?
    
    init(list: AuthorList) {
        mode = .update(list: list)
        _authors = State(initialValue: list.allAuthors)
        onSave = nil
    }
    
    init(title: String, description: String?, onSave: (() -> Void)?) {
        mode = .create(title: title, description: description)
        _authors = State(initialValue: [])
        self.onSave = onSave
    }
    
    var body: some View {
        ZStack {
            Color.appBg
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                if case .create = mode {
                    Text("listStep2")
                        .font(.clarity(.medium, textStyle: .subheadline))
                        .foregroundColor(Color.secondaryTxt)
                        .padding(EdgeInsets(top: 28, leading: 20, bottom: 0, trailing: 16))
                }
                
                AuthorSearchView(
                    searchOrigin: .lists,
                    isModal: false,
                    avatarOverlayMode: .inSet(authors: authors),
                    emptyPlaceholder: {
                        AuthorsView(
                            authors: Array(authors),
                            avatarOverlayMode: .alwaysSelected,
                            onTapGesture: toggleAuthor
                        )
                    },
                    didSelectGesture: toggleAuthor
                )
            }
        }
        .nosNavigationBar(title: AttributedString(viewTitle))
        .toolbar {
            if case .update = mode {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") {
                        dismiss()
                    }
                }
            }
            ToolbarItem(placement: .primaryAction) {
                ActionButton(mode.buttonTitleKey, action: saveButtonPressed)
                    .frame(height: 22)
                    .padding(.bottom, 3)
            }
        }
    }
    
    private var viewTitle: String {
        switch mode {
        case .create(let title, _):
            title
        case .update(let list):
            list.title ?? ""
        }
    }
    
    private var buttonTitleKey: LocalizedStringKey {
        switch mode {
        case .create:
            "save"
        case .update:
            "done"
        }
    }
    
    private func toggleAuthor(_ author: Author) {
        if authors.contains(author) {
            authors.remove(author)
        } else {
            authors.insert(author)
        }
    }
    
    private func saveButtonPressed() {
        guard let keyPair = currentUser.keyPair else {
            return
        }
        
        let title: String
        let description: String?
        let replaceableID: String?
        
        switch mode {
        case .create(let newTitle, let newDescription):
            title = newTitle
            description = newDescription
            replaceableID = nil
        case .update(let list):
            title = list.title ?? ""
            description = list.listDescription
            replaceableID = list.replaceableIdentifier
        }
        
        let event = JSONEvent.followSet(
            pubKey: keyPair.publicKeyHex,
            title: title,
            description: description,
            replaceableID: replaceableID,
            authorIDs: authors.compactMap { $0.hexadecimalPublicKey }
        )
        
        Task {
            do {
                try await relayService.publishToAll(event: event, signingKey: keyPair, context: viewContext)
                
                if let onSave {
                    onSave()
                } else {
                    dismiss()
                }
            } catch {
                Log.error("Error when creating list: \(error.localizedDescription)")
            }
        }
    }
}
