import CoreData
import SwiftUI

struct ListsDestination: Hashable {
    let author: Author
}

struct ListsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    let author: Author
    
    @FetchRequest var lists: FetchedResults<AuthorList>
    
    init(author: Author) {
        self.author = author
        _lists = FetchRequest(fetchRequest: AuthorList.authorLists(ownedBy: author))
    }
    
    var body: some View {
        ZStack {
            Color.appBg
            
            Group {
                if lists.isEmpty {
                    VStack {
                        Image(systemName: "person.2")
                        
                        Text("Add your favorite accounts to public lists and pin them to your home feed")
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(lists) { list in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(list.title ?? "")
                                            .font(.body)
                                        
                                        if let description = list.listDescription {
                                            Text(description)
                                                .foregroundStyle(Color.secondaryTxt)
                                                .font(.footnote)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Menu {
                                        Button("editListInfo") {
                                            // TODO: Edit List Info
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
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .frame(minHeight: 50)
                                
                                BeveledSeparator()
                            }
                        }
                        .background(LinearGradient.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .mimicCardButtonStyle()
                    }
                    .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                }
            }
        }
        .scrollContentBackground(.hidden)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                ActionButton("new", action: newButtonPressed)
                    .frame(height: 22)
                    .padding(.bottom, 3)
            }
        }
        .nosNavigationBar("yourLists")
    }
    
    private func newButtonPressed() {
        
    }
}
