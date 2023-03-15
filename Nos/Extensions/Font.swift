//
//  Font.swift
//  Hockey
//
//  Created by @yspreen on 11/11/22.
//

import SwiftUI

// https://stackoverflow.com/a/74416073
extension Font {
    static var clarity = Font
        .custom("ClarityCity-Regular", size: UIFont.preferredFont(
            forTextStyle: .body
        ).pointSize)
    
    static var clarityBold = Font
        .custom("ClarityCity-Bold", size: UIFont.preferredFont(
            forTextStyle: .body
        ).pointSize)
    
    static var clarityCaption = Font
        .custom("ClarityCity-Regular", size: UIFont.preferredFont(
            forTextStyle: .caption1
        ).pointSize)
    
    static var brand = Font
        .custom("ClarityCity-Regular", size: UIFont.preferredFont(
            forTextStyle: .body
        ).pointSize)

    static func setUp() {
        let appearance = UINavigationBar.appearance()
        let largeTitle = UIFont.preferredFont(
            forTextStyle: .largeTitle
        ).pointSize
        let body = UIFont.preferredFont(
            forTextStyle: .body
        ).pointSize
        let caption1 = UIFont.preferredFont(
            forTextStyle: .caption1
        ).pointSize

        print(UIFont.preferredFont(forTextStyle: .largeTitle))
        appearance.largeTitleTextAttributes = [
            .font: UIFont(
                name: "ClarityCity-Bold", size: largeTitle
            )!
        ]
        appearance.titleTextAttributes = [
            .font: UIFont(
                name: "ClarityCity-Medium", size: body
            )!
        ]

        UITabBarItem.appearance().setTitleTextAttributes(
            [.font: UIFont(name: "ClarityCity-Regular", size: caption1)!],
            for: .normal
        )
        UITabBarItem.appearance().setTitleTextAttributes(
            [.font: UIFont(name: "ClarityCity-Regular", size: caption1)!],
            for: .selected
        )
    }
}

// swiftlint:disable identifier_name
func PlainText(_ content: any StringProtocol) -> SwiftUI.Text {
    SwiftUI.Text(content)
}

func Text(_ content: any StringProtocol) -> SwiftUI.Text {
    .init(content).font(.brand)
}

func TextField(_ titleKey: LocalizedStringKey, text: Binding<String>, axis: Axis = .horizontal) -> some View {
    SwiftUI.TextField(titleKey, text: text, axis: axis).font(.brand)
}

func TextField<Label: View>(text: Binding<String>, prompt: Text? = nil, label: () -> Label) -> some View {
    SwiftUI.TextField(text: text, prompt: prompt?.font(.brand), label: label).font(.brand)
}
// swiftlint:enableidentifier_name
