//
//  AsyncButton.swift
//  Nos
//
//  Created by Matthew Lorentz on 4/21/23.
//

import SwiftUI

/// A button that executes an `async` action and shows a progress wheel when tapped.
struct AsyncButton<Label: View>: View {
    
    var action: () async -> Void
    @ViewBuilder var label: () -> Label
    var loadingIndicatorColor: Color = .primaryTxt
    var backgroundColor: Color = .cardBackground
    
    @State private var loading = false
    
    var body: some View {
        Button(
            action: { 
                loading = true
                Task { 
                    await action() 
                    loading = false
                }
            }, 
            label: {
                label()
                    .overlay(Group {
                        if loading {
                            Rectangle().foregroundColor(backgroundColor)
                                .overlay(ProgressView().foregroundColor(loadingIndicatorColor))
                        } else {
                            EmptyView()
                        }
                    })
            }
        )
    }
}

struct AsyncButton_Previews: PreviewProvider {
    static var previews: some View {
        AsyncButton {
            do {
                try await Task.sleep(nanoseconds: UInt64(2 * 1_000_000_000))
            } catch {
                print(error)
            }
        } label: { 
            Image(systemName: "arrow.uturn.left.circle")
        }
    }
}
