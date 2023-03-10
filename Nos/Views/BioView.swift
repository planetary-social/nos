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

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(bio ?? "")
                .lineLimit(5)
                .padding(EdgeInsets(top: 0, leading: 18, bottom: 9, trailing: 18))
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
                    Text(bio ?? "")
                        .padding(EdgeInsets(top: 0, leading: 18, bottom: 9, trailing: 18))
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
                        PlainText(Localized.readMore.string.uppercased())
                            .font(.clarityCaption)
                            .foregroundColor(.secondaryTxt)
                            .padding(EdgeInsets(top: 4, leading: 6, bottom: 4, trailing: 6))
                            .background(Color.hashtagBg)
                            .cornerRadius(4)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 0))
            }
        }
        .placeholder(when: isLoading) {
            Text(String.loremIpsum(1))
                .lineLimit(5)
                .padding(EdgeInsets(top: 0, leading: 18, bottom: 9, trailing: 18))
                .redacted(reason: .placeholder)
        }
        .sheet(isPresented: $showingBio) {
            NavigationView {
                SelectableText(bio ?? "")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.cardBackground)
                    .navigationTitle(Localized.bio.string)
                    .navigationBarTitleDisplayMode(.inline)
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
    }

    private func updateShouldShowReadMore() {
        shouldShowReadMore = intrinsicSize != truncatedSize
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
        .background(Color.cardBackground)
    }
}
