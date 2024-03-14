import Foundation
import SwiftUI
struct DiscoverSearchBar: View {
    @State private var text = ""
    let placeholder: String
    let onSubmitSearch: (String) -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
            TextField(placeholder, text: $text)
                .foregroundColor(.primary)
                .onSubmit {
                    onSubmitSearch(text)
                }
                .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 5)
        .background(Color(.systemGray5))
        .cornerRadius(10)
        .frame(maxWidth: .infinity) 
    }
}
// "Find a user by ID"
