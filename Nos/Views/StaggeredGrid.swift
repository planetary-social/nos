//
//  StaggeredGrid.swift
//  Nos
//
//  Created by Matthew Lorentz on 3/8/23.
//

import SwiftUI

struct StaggeredGrid<Content: View, T: Identifiable, L: RandomAccessCollection<T>>: View where T: Hashable {
    
    var content: (T) -> Content
    
    var list: L
    
    var columns: Int
    var spacing: CGFloat
    
    init(list: L, columns: Int, spacing: CGFloat = 10, @ViewBuilder content: @escaping (T) -> Content) {
        self.content = content
        self.list = list
        self.spacing = spacing
        self.columns = columns
    }
    
    func setUpList() -> [[T]] {
        var gridArray: [[T]] = Array(repeating: [], count: columns)
        
        guard columns > 0 else {
            return gridArray
        }
        
        var currentIndex = 0
        
        for object in list {
            gridArray[currentIndex].append(object)
            
            if currentIndex == columns - 1 {
                currentIndex = 0
            } else {
                currentIndex += 1
            }
        }
        
        return gridArray
    }
    
    var body: some View {
        ScrollView(.vertical) {
            HStack(alignment: .top) {
                ForEach(setUpList(), id: \.self) { columnsData in
                    LazyVStack(spacing: spacing) {
                        ForEach(columnsData) { model in
                            content(model)
                        }
                    }
                }
            }
            .padding(.top, 10)
        }
    }
}
