//
//  SearchBar.swift
//  Nos
//
//  Created by Matthew Lorentz on 5/15/23.
//

import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    var isSearching: FocusState<Bool>.Binding
    
    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 8) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color(.systemGray))
                    TextField("Search", text: $text)
                        .font(.clarity)
                        .foregroundColor(.primaryTxt)
                        .onTapGesture {
                            isSearching.wrappedValue = true // Set focus to the search bar when tapped
                        }
                        .focused(isSearching)
                    Spacer()
                }
                .padding(8)
            }
            .background(Color.cardBgBottom)
            .cornerRadius(8)
            
            if isSearching.wrappedValue {
                Button(action: {
                    text = "" // Clear the search text
                    isSearching.wrappedValue = false // Remove focus from the search bar
                }, label: {
                    Text(.localizable.clear)
                        .foregroundLinearGradient(.horizontalAccent)
                })
                .transition(.move(edge: .trailing))
                .animation(.spring(), value: isSearching.wrappedValue)
            }
        }
        .padding(16)
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
