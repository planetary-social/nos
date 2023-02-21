//
//  Profile.swift
//  Nos
//
//  Created by Christopher Jorgensen on 2/21/23.
//

import Foundation

enum Profile {
    static var author: Author? {
        didSet {
            if author != nil {
                print("👉Got author \(author!.hexadecimalPublicKey!). Getting follows.")
                let filter = Filter(authors: [author!], kinds: [.contactList], limit: 1)
                Profile.relayService?.requestEventsFromAll(filter: filter)
            } else {
                print("👉Warning: erased Profile author")
            }
        }
    }
    static var follows: [Follow]? {
        didSet {
            print("👉Profile has \(follows?.count ?? 0) follows. Requesting texts.")
            
            let authors = follows?.map { $0.event!.author! } ?? []
            let filter = Filter(authors: authors, kinds: [.text], limit: 100)
            Profile.relayService?.requestEventsFromAll(filter: filter)
        }
    }
    static var relayService: RelayService?
}
