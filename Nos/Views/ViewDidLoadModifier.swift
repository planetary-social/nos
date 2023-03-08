//
//  ViewDidLoadModifier.swift
//  Nos
//
//  Created by Matthew Lorentz on 3/8/23.
//

import SwiftUI

/// Like .onAppear but is only called once.
/// From https://sarunw.com/posts/swiftui-viewdidload/
struct ViewDidLoadModifier: ViewModifier {
    @State private var viewDidLoad = false
    let action: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                if viewDidLoad == false {
                    viewDidLoad = true
                    action?()
                }
            }
    }
}

extension View {
    func onViewDidLoad(perform action: (() -> Void)? = nil) -> some View {
        self.modifier(ViewDidLoadModifier(action: action))
    }
}

