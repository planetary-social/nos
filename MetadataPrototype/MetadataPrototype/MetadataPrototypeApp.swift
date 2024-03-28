//
//  MetadataPrototypeApp.swift
//  MetadataPrototype
//
//  Created by Josh on 3/25/24.
//

import SwiftUI

@main
struct MetadataPrototypeApp: App {
    var body: some Scene {
        WindowGroup {
            ScrollView {
                VStack {
                    LinkPreview(url: URL(string: "https://arstechnica.com/space/2024/03/its-a-few-years-late-but-a-prototype-supersonic-airplane-has-taken-flight/")!)
                    LinkPreview(url: URL(string: "https://image.nostr.build/ce70e9c25fdf90405ff598c45db9cdf6d3bbac12a72c35495f95cd01e2ed6c07.jpg")!, showUrl: false, showTitle: false)
                    LinkPreview(url: URL(string: "https://glass.photo/jtbrown/zY8mJtzwnT3tQlMyVvyUs")!)
                    LinkPreview(url: URL(string: "https://www.macrumors.com/2024/03/23/relocated-apple-square-one-opens/")!)
                    LinkPreview(url: URL(string: "https://www.swiftuifieldguide.com/layout/safe-area/")!)
                }
            }
        }
    }
}
