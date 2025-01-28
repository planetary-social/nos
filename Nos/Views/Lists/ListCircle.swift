import SwiftUI

/// A white circle with a group icon in it for representing an ``AuthorList``.
struct ListCircle: View {
    var body: some View {
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
    }
}
