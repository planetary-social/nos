import SwiftUI

/// A simple repeating Grid Pattern, useful for previews and debugging.
struct GridPattern: View {
    var body: some View {
        GeometryReader { geometry in
            let rowHeight = 50
            let columnWidth = 50
            
            let rows = Int(geometry.size.height / CGFloat(rowHeight))
            let columns = Int(geometry.size.width / CGFloat(columnWidth))
            
            let rowIndices = Array(0..<rows)
            let columnIndices = Array(0..<columns)
            
            ZStack {
                ForEach(rowIndices, id: \.self) { row in
                    ForEach(columnIndices, id: \.self) { column in
                        Rectangle()
                            .fill((row + column).isMultiple(of: 2) ? Color.gray : Color.white) 
                            .frame(width: CGFloat(columnWidth), height: CGFloat(rowHeight))
                            .offset(x: CGFloat(column) * CGFloat(columnWidth), y: CGFloat(row) * CGFloat(rowHeight))
                    }
                }
            }
        }
    }
}

#Preview {
    GridPattern()
}
