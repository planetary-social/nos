import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    var isSearching: FocusState<Bool>.Binding
    var placeholder = String(localized: "Search")

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 8) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color(.secondaryTxt))
                    TextField("", text: $text)
                        .font(.clarity(.regular))
                        .foregroundColor(.primaryTxt)
                        .modifier(
                            PlaceholderStyle(
                                show: $text.wrappedValue.isEmpty,
                                placeholder: placeholder,
                                placeholderColor: .secondaryTxt,
                                font: .caption
                            )
                        )
                        .onTapGesture {
                            isSearching.wrappedValue = true // Set focus to the search bar when tapped
                        }
                        .focused(isSearching)
                        .submitLabel(.search)
                    Spacer()
                }
                .padding(10)
            }
            .background(Color.searchBarBg)
            .cornerRadius(10)

            if isSearching.wrappedValue {
                Button(action: {
                    text = "" // Clear the search text
                    isSearching.wrappedValue = false // Remove focus from the search bar
                }, label: {
                    Text("clear")
                        .foregroundLinearGradient(.horizontalAccent)
                })
                .transition(.move(edge: .trailing))
                .animation(.spring(), value: isSearching.wrappedValue)
            }
        }
        .padding(16)
        .shadow(color: Color.searchBarOuterShadow, radius: 0, x: 0, y: 0.31)
    }
}

struct SearchBar_Previews: PreviewProvider {
    
    @State static var emptyText: String = ""
    @State static var text: String = "Martin"
    @FocusState static var isSearching: Bool 
    
    static var previews: some View {
        Group {
            VStack {
                SearchBar(text: $emptyText, isSearching: $isSearching)
                ForEach(0..<5) { _ in 
                    Text(String.loremIpsum(1))
                }
            }
            .background(Color.appBg)
        }
        
        Group {
            VStack {
                SearchBar(text: $text, isSearching: $isSearching)
                ForEach(0..<5) { _ in 
                    Text(String.loremIpsum(1))
                }
            }
            .background(Color.appBg)
            .onAppear {
                isSearching = true // this doesn't work for some reason
            }
        }
    }
}
