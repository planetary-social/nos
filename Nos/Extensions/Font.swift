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
    
    static var clarityMedium = Font
        .custom("ClarityCity-Medium", size: UIFont.preferredFont(
            forTextStyle: .body
        ).pointSize)
    
    static var clarityBold = Font
        .custom("ClarityCity-Bold", size: UIFont.preferredFont(
            forTextStyle: .body
        ).pointSize)
    
    static var clarityTitle = Font
        .custom("ClarityCity-Bold", size: UIFont.preferredFont(
            forTextStyle: .title1
        ).pointSize)
    
    static var clarityTitle2 = Font
        .custom("ClarityCity-Bold", size: UIFont.preferredFont(
            forTextStyle: .title2
        ).pointSize)
    
    static var clarityTitle3 = Font
        .custom("ClarityCity-Bold", size: UIFont.preferredFont(
            forTextStyle: .title3
        ).pointSize)
    
    static var clarityHeadline = Font
        .custom("ClarityCity-Bold", size: UIFont.preferredFont(forTextStyle: .headline).pointSize)
    
    static var clarityCaption = Font
        .custom("ClarityCity-Regular", size: UIFont.preferredFont(
            forTextStyle: .caption1
        ).pointSize)
    
    static var clarityCaption2 = Font
        .custom("ClarityCity-Regular", size: UIFont.preferredFont(
            forTextStyle: .caption2
        ).pointSize)
    
    static var clarityCallout = Font
        .custom("ClarityCity-Regular", size: UIFont.preferredFont(
            forTextStyle: .callout
        ).pointSize)

    static var claritySubheadline = Font
        .custom("ClarityCity-Medium", size: UIFont.preferredFont(
            forTextStyle: .subheadline
        ).pointSize)
    
    static var clarityFootnote = Font
        .custom("ClarityCity-Regular", size: UIFont.preferredFont(
            forTextStyle: .footnote
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

extension UIFont {
    
    static var clarity = UIFont(
        name: "ClarityCity-Regular",
        size: UIFont.preferredFont(forTextStyle: .body).pointSize
    )!
    
    static var clarityBold = UIFont(
        name: "ClarityCity-Bold",
        size: UIFont.preferredFont(forTextStyle: .body).pointSize
    )!
}

// swiftlint:disable identifier_name
func PlainText(_ content: any StringProtocol) -> SwiftUI.Text {
    SwiftUI.Text(content)
}

func PlainText(_ localizedStringResource: LocalizedStringResource) -> SwiftUI.Text {
    SwiftUI.Text(localizedStringResource)
}

func PlainTextField<Label: View>(text: Binding<String>, prompt: Text? = nil, label: () -> Label) -> some View {
    SwiftUI.TextField(text: text, prompt: prompt, label: label)
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
// swiftlint:enable identifier_name
