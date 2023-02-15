//
//  CompactNoteView.swift
//  Planetary
//
//  Created by Martin Dutra on 28/10/22.
//  Copyright © 2022 Verse Communications Inc. All rights reserved.
//

import SwiftUI

/// A view that displays the text of a note (kind: 1 Nostr event) and truncates it with a "Read more" button if
/// it is too long
struct CompactNoteView: View {

    var note: Event

    @State
    private var shouldShowReadMore = false

    @State
    private var intrinsicSize = CGSize.zero

    @State
    private var truncatedSize = CGSize.zero

    func updateShouldShowReadMore() {
        shouldShowReadMore = intrinsicSize != truncatedSize
    }
    
    @EnvironmentObject var router: Router
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(note.content ?? "")
                .lineLimit(5)
                .font(.body)
                .foregroundColor(.primaryTxt)
                .accentColor(.accent)
                .padding(15)
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
                    Text(note.content ?? "")
                        .font(.body)
                        .padding(15)
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
            if shouldShowReadMore {
                
                ZStack(alignment: .center) {
                    Button {
                        router.path.append(note)
                    } label: {
                        Text("Read more".uppercased())
                            .font(.caption)
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
        .navigationDestination(for: Event.self, destination: { note in
            ThreadView(note: note)
        })
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

fileprivate struct IntrinsicSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}

fileprivate struct TruncatedSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}

struct CompactNoteView_Previews: PreviewProvider {
    
    static var persistenceController = PersistenceController.preview
    static var previewContext = persistenceController.container.viewContext
    
    static var shortNote: Event {
        let note = Event(context: previewContext)
        note.content = "Hello, world!"
        return note
    }
    
    static var longNote: Event {
        let note = Event(context: previewContext)
        note.content = .loremIpsum(5)
        return note
    }
    
    static var previews: some View {
        Group {
            VStack {
                CompactNoteView(note: shortNote)
            }
            VStack {
                CompactNoteView(note: longNote)
            }
        }
        .padding()
        .background(Color.cardBackground)
    }
}
