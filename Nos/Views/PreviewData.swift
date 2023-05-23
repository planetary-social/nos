//
//  PreviewData.swift
//  Nos
//
//  Created by Matthew Lorentz on 5/9/23.
//

import SwiftUI
import Foundation

enum PreviewData {
    
    static var persistenceController = PersistenceController.preview
    static var previewContext = persistenceController.container.viewContext
    static var router = Router()
    static var emptyPersistenceController = PersistenceController.empty
    static var emptyPreviewContext = emptyPersistenceController.container.viewContext
    static var emptyRelayService = RelayService(persistenceController: emptyPersistenceController)
    static var relayService = RelayService(persistenceController: persistenceController)

    @MainActor static var currentUser: CurrentUser = {
        let currentUser = CurrentUser(persistenceController: persistenceController)
        currentUser.viewContext = previewContext
        currentUser.relayService = relayService
        Task { await currentUser.setKeyPair(KeyFixture.keyPair) }
        return currentUser
    }()

    static var previewAuthor: Author = {
        let author = Author(context: previewContext)
        author.hexadecimalPublicKey = KeyFixture.alice.publicKeyHex
        author.profilePhotoURL = URL(string: "https://avatars.githubusercontent.com/u/1165004?s=40&v=4")
        return author
    }()
    
    static var shortNote: Event {
        let note = Event(context: previewContext)
        note.identifier = "1"
        note.content = "Hello, world!"
        note.author = previewAuthor
        note.createdAt = .now
        try! previewContext.save()
        return note
    }
    
    static var imageNote: Event {
        let note = Event(context: previewContext)
        note.identifier = "2"
        note.content = "Hello, world!https://cdn.ymaws.com/nacfm.com/resource/resmgr/images/blog_photos/footprints.jpg"
        note.author = previewAuthor
        note.createdAt = .now
        try! previewContext.save()
        return note
    }
    
    static var verticalImageNote: Event {
        let note = Event(context: previewContext)
        note.identifier = "3"
        // swiftlint:disable line_length
        note.content = "Hello, world!https://nostr.build/i/nostr.build_1b958a2af7a2c3fcb2758dd5743912e697ba34d3a6199bfb1300fa6be1dc62ee.jpeg"
        // swiftlint:enable line_length
        note.author = previewAuthor
        note.createdAt = .now
        try! previewContext.save()
        return note
    }
    
    static var veryWideImageNote: Event {
        let note = Event(context: previewContext)
        // swiftlint:disable line_length
        note.identifier = "4"
        note.content = "Hello, world! https://nostr.build/i/nostr.build_db8287dde9aedbc65df59972386fde14edf9e1afc210e80c764706e61cd1cdfa.png"
        // swiftlint:enable line_length
        note.author = previewAuthor
        note.createdAt = .now
        try! previewContext.save()
        return note
    }
    
    static var longNote: Event {
        let note = Event(context: previewContext)
        note.identifier = "5"
        note.createdAt = .now
        note.content = .loremIpsum(5)
        note.author = previewAuthor
        try! previewContext.save()
        return note
    }
    
    static var longFormNote: Event {
        let note = Event(context: previewContext)
        note.identifier = "6"
        note.createdAt = .now
        note.kind = EventKind.longFormContent.rawValue
        note.content = 
        """
        # This note
        
        is **formatted** with
        > _markdown_
        
        And it has a link to [nos.social](https://nos.social).
        """
        note.author = previewAuthor
        try! previewContext.save()
        return note
    }
}
