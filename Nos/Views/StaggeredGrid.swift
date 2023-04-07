//
//  StaggeredGrid.swift
//  Nos
//
//  Created by Matthew Lorentz on 3/8/23.
//

import SwiftUI

// class StaggeredGridDataSource<E>: RandomAccessCollection {
//
//    var columnCount: Int
//    var flatCollection: any RandomAccessCollection<E> where Index == Int
//
//    typealias Index = (x: Int, y: Int)
//
//    typealias Element = E
//
//    init(columnCount: Int, collection: any RandomAccessCollection<E>) {
//        self.columnCount = columnCount
//        self.flatCollection = collection
//    }
//
//    func index(after i: Index) -> Index {
//        if i.x == columnCount - 1 {
//            return (x: 0, y: i.y + 1)
//        } else {
//            return (x: i.x + 1, y: i.y)
//        }
//    }
//
//    func index(before i: Index) -> Index {
//        if i.x == 0 {
//            return (x: columnCount - 1, y: i.y - 1)
//        } else {
//            return (x: i.x - 1, y: i.y)
//        }
//    }
//
//    subscript(position: Index) -> E {
//        flatCollection[position.y * columnCount + position.x]
//    }
//
//    var startIndex: Index {
//        (x: 0, y: 0)
//    }
//
//    var endIndex: Index {
//        let numberOfRows = Int(flatCollection.count / columnCount)
//        let remainder = flatCollection.count % columnCount
//        return (x: remainder, y: numberOfRows)
//    }
//
// }

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
            .padding(.horizontal)
        }
    }
}
