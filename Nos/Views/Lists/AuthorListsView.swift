import CoreData
import SwiftUI

struct ListsDestination: Hashable {
    let author: Author
}

/// A view that displays a list of an ``Author``'s ``AuthorList``s.
struct AuthorListsView: View {
    
    @EnvironmentObject private var router: Router
    let author: Author
    
    @FetchRequest var lists: FetchedResults<AuthorList>
    
    @State private var showingCreateList = false
    
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
                        ListCircle()
                        
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
                                Button {
                                    router.pushList(list)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(list.title ?? "")
                                                .font(.body)
                                            
                                            Text(list.rowDescription)
                                                .foregroundStyle(Color.secondaryTxt)
                                                .font(.footnote)
                                                .lineLimit(1)
                                        }
                                        
                                        Spacer()
                                    }
                                    .padding(.leading, 16)
                                    .padding(.vertical, 12)
                                    .frame(minHeight: 50)
                                }
                                
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
        .sheet(isPresented: $showingCreateList) {
            NavigationStack {
                EditAuthorListView()
            }
        }
    }
    
    private func newButtonPressed() {
        showingCreateList = true
    }
}

extension AuthorList {
    
    var rowDescription: String {
        var descriptionComponents = [String]()
        let authorCount = allAuthors.count
        let countString = String.localizedStringWithFormat(String(localized: "xUsers"), authorCount)
        descriptionComponents.append(countString)
        
        let description = listDescription?.isEmpty == false ? listDescription! : String(localized: "noDescription")
        descriptionComponents.append(description)
        return descriptionComponents.joined(separator: " • ")
    }
}
