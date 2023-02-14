//
//  ThreadView.swift
//  Nos
//
//  Created by Matthew Lorentz on 2/14/23.
//

import SwiftUI

struct ThreadView: View {
    var note: Event
    var body: some View {
        Text("Thread view placeholder for note: \(note.identifier ?? "no id")")
    }
}

//struct ThreadView_Previews: PreviewProvider {
//    static var previews: some View {
//        ThreadView()
//    }
//}
