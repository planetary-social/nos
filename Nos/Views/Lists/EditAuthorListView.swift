import Logger
import SwiftUI

struct EditAuthorListView: View {
    enum Mode {
        case create
        case update
    }
    
    enum Field: Hashable {
        case title, description
    }
    
    @Environment(\.dismiss) private var dismiss
    @Environment(RelayService.self) private var relayService
    @Environment(CurrentUser.self) private var currentUser
    @Environment(\.managedObjectContext) private var viewContext
    
    let list: AuthorList?
    
    @State private var title: String = ""
    @State private var description: String = ""
    @FocusState private var focusedField: Field?
    private let mode: Mode
    
    init(list: AuthorList? = nil) {
        self.list = list
        mode = list == nil ? .create : .update
        
        title = list?.title ?? ""
        description = list?.listDescription ?? ""
    }
    
    var body: some View {
        ZStack {
            Color.appBg
                .ignoresSafeArea()
            
            VStack(alignment: .leading) {
                if mode == .create {
                    Text("listStep1")
                        .font(.clarity(.medium, textStyle: .subheadline))
                        .foregroundColor(Color.secondaryTxt)
                        .padding(EdgeInsets(top: 20, leading: 20, bottom: 0, trailing: 16))
                }
                
                NosForm {
                    NosFormSection("listName") {
                        NosTextField(text: $title)
                            .padding(20)
                            .focused($focusedField, equals: .title)
                    }
                    .padding(.top, 20)
                    
                    NosFormSection("description") {
                        NosTextEditor(text: $description)
                            .focused($focusedField, equals: .description)
                            .padding()
                            .frame(minHeight: 200, maxHeight: 250)
                    }
                    .padding(.top, 20)
                }
            }
        }
        .nosNavigationBar(mode == .create ? "newList" : "editListInfo")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .primaryAction) {
                ActionButton(mode == .create ? "next" : "save", action: saveButtonPressed)
                    .frame(height: 22)
                    .padding(.bottom, 3)
            }
        }
        .onAppear {
            title = list?.title ?? ""
            description = list?.listDescription ?? ""
            
            focusedField = .title
        }
    }
    
    private func saveButtonPressed() {
        guard !title.isEmpty else {
            focusedField = .title
            return
        }
        
        guard let keyPair = currentUser.keyPair else {
            return
        }
        
        if mode == .update {
            let event = JSONEvent.followSet(
                pubKey: keyPair.publicKeyHex,
                title: title,
                description: description,
                replaceableID: list?.replaceableIdentifier,
                authorIDs: []
            )
            
            Task {
                do {
                    try await relayService.publishToAll(event: event, signingKey: keyPair, context: viewContext)
                    dismiss()
                } catch {
                    Log.error("Error when creating list: \(error.localizedDescription)")
                }
            }
        } else {
            // TODO: Manage Users
        }
    }
}
