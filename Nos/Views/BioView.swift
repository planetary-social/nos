//
//  BioView.swift
//  Planetary
//
//  Created by Martin Dutra on 19/11/22.
//  Copyright © 2022 Verse Communications Inc. All rights reserved.
//

import SwiftUI

struct BioView: View {

    var bio: String?

    @State
    private var showingBio = false
    
    @State
    private var shouldShowReadMore = false

    @State
    private var intrinsicSize = CGSize.zero

    @State
    private var truncatedSize = CGSize.zero

    private var isLoading: Bool {
        bio == nil
    }

    private let lineSpacing: CGFloat = 7

    private let lineLimit: Int = 5

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(LocalizedStringKey(bio ?? ""))
                .foregroundColor(.primaryTxt)
                .tint(.accent)
                .lineSpacing(lineSpacing)
                .lineLimit(lineLimit)
                .padding(EdgeInsets(top: 0, leading: 18, bottom: 0, trailing: 18))
                .background {
                    GeometryReader { geometryProxy in
                        Color.clear.preference(key: TruncatedSizePreferenceKey.self, value: geometryProxy.size)
                    }
                }
                .onPreferenceChange(TruncatedSizePreferenceKey.self) { newSize in
                    if newSize.height > truncatedSize.height {
                        truncatedSize = newSize
                        updateShouldShowReadMore()
                    }
                }
                .background {
                    Text(LocalizedStringKey(bio ?? ""))
                        .lineSpacing(lineSpacing)
                        .padding(EdgeInsets(top: 0, leading: 18, bottom: 0, trailing: 18))
                        .fixedSize(horizontal: false, vertical: true)
                        .hidden()
                        .background {
                            GeometryReader { geometryProxy in
                                Color.clear.preference(key: IntrinsicSizePreferenceKey.self, value: geometryProxy.size)
                            }
                        }
                        .onPreferenceChange(IntrinsicSizePreferenceKey.self) { newSize in
                            if newSize.height > intrinsicSize.height {
                                intrinsicSize = newSize
                                updateShouldShowReadMore()
                            }
                        }
                }
                .onTapGesture {
                    showingBio = true
                }
            if shouldShowReadMore {
                ZStack(alignment: .center) {
                    Button {
                        showingBio = true
                    } label: {
                        PlainText(String(localized: .localizable.readMore).uppercased())
                            .font(.clarityCaption)
                            .foregroundColor(.secondaryTxt)
                            .padding(EdgeInsets(top: 4, leading: 6, bottom: 4, trailing: 6))
                            .background(Color.hashtagBg)
                            .cornerRadius(4)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(EdgeInsets(top: 3, leading: 0, bottom: 1, trailing: 0))
            }
        }
        .placeholder(when: isLoading) {
            Text(String.loremIpsum(1))
                .lineSpacing(lineSpacing)
                .lineLimit(5)
                .padding(EdgeInsets(top: 0, leading: 18, bottom: 0, trailing: 18))
                .redacted(reason: .placeholder)
        }
        .sheet(isPresented: $showingBio) {
            NavigationView {
                SelectableText(bio ?? "")
                    .foregroundColor(.primaryTxt)
                    .nosNavigationBar(title: .localizable.bio)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.appBg)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                showingBio = false
                            } label: {
                                Image.navIconDismiss
                            }
                        }
                    }
            }
        }
        .padding(0)
    }

    private func updateShouldShowReadMore() {
        shouldShowReadMore = intrinsicSize.height != truncatedSize.height
    }

    fileprivate struct IntrinsicSizePreferenceKey: PreferenceKey {
        static var defaultValue: CGSize = .zero
        static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
    }

    fileprivate struct TruncatedSizePreferenceKey: PreferenceKey {
        static var defaultValue: CGSize = .zero
        static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
    }
}

struct BioView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            BioView(bio: nil)
            BioView(bio: .loremIpsum(1))
            BioView(bio: .loremIpsum(3))
        }
        .padding()
        .background(Color.previewBg)
    }
}
