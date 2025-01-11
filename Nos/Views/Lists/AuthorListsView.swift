import CoreData
import SwiftUI

struct ListsDestination: Hashable {
    let author: Author
}

/// A view that displays a list of an ``Author``'s ``AuthorList``s.
struct AuthorListsView: View {
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
                .ignoresSafeArea()
            
            Group {
                if lists.isEmpty {
                    VStack(spacing: 40) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "person.2")
                                .resizable()
                                .fontWeight(.semibold)
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 48)
                                .foregroundStyle(Color.black)
                        }
                        
                        Text("listsDescription")
                            .font(.subheadline.weight(.medium))
                            .multilineTextAlignment(.center)
                        
                        Spacer()
                    }
                    .padding(.top, 100)
                    .padding(.horizontal, 60)
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(lists) { list in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(list.title ?? "")
                                            .font(.body)
                                        
                                        Text(list.rowDescription)
                                            .foregroundStyle(Color.secondaryTxt)
                                            .font(.footnote)
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
        // TODO
    }
}

extension AuthorList {
    
    var rowDescription: String {
        var descriptionComponents = [String]()
        let authorCount = allAuthors.count
        let countString = String.localizedStringWithFormat(String(localized: "xUsers"), authorCount)
        descriptionComponents.append(countString)
        
        descriptionComponents.append(listDescription ?? String(localized: "noDescription"))
        return descriptionComponents.joined(separator: " • ")
    }
}
