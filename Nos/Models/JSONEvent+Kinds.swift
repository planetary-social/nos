import Foundation

extension JSONEvent {
    
    /// An event that represents the user's contact list (who they are following) and their relays.
    /// - Parameters:
    ///   - pubKey: The pubkey of the user whose contact list and relays the event represents.
    ///   - tags: The "p" tags of followed profiles.
    ///   - relays: Relays the user wishes to associate with their profile.
    /// - Returns: The ``JSONEvent`` of the contact list.
    static func contactList(pubKey: String, tags: [[String]], relayAddresses: [String]) -> JSONEvent {
        var tags = tags
        // Note: We don't need to add client tag here as it will be added in the JSONEvent initializer
        
        let relayStrings = relayAddresses.map { "\"\($0)\":{\"write\":true,\"read\":true}" }
        let content = "{" + relayStrings.joined(separator: ",") + "}"
        
        return JSONEvent(
            pubKey: pubKey,
            kind: .contactList,
            tags: tags,
            content: content
        )
    }
    
    /// An event that represents the user's request for all of their published notes to be removed from relays.
    /// - Parameters:
    ///   - pubKey: The public key of the user making the request.
    ///   - relays: The relays to request removal from. Note: A nil or empty relay array will be interpreted to mean
    ///             that the user seeks removal from all relays.
    ///   - reason: The reason the user wishes to have their content removed. Optional.
    /// - Returns: The ``JSONEvent`` representing the request.
    static func requestToVanish(pubKey: String, relays: [URL]? = nil, reason: String? = nil) -> JSONEvent {
        let tags: [[String]]
        if let relays, !relays.isEmpty {
            tags = relays.map { ["relay", $0.absoluteString] }
        } else {
            tags = [["relay", "ALL_RELAYS"]]
        }
        
        return JSONEvent(
            pubKey: pubKey,
            kind: .requestToVanish,
            tags: tags,
            content: reason ?? ""
        )
    }
    
    /// An event that represents a list of authors.
    /// - Parameters:
    ///   - pubKey: The public key of the user making the request.
    ///   - title: The title of the list.
    ///   - description: An optional description of the list.
    ///   - replaceableID: The unique identifier of the list. If left nil, one will be provided as a UUID.
    ///   - authorIDs: A list of author ids to add to the list.
    /// - Returns: The ``JSONEvent`` representing the list.
    static func followSet(
        pubKey: String,
        title: String,
        description: String?,
        replaceableID: RawReplaceableID?,
        authorIDs: [RawAuthorID]
    ) -> JSONEvent {
        let identifier = replaceableID ?? UUID().uuidString
        
        var tags = [
            ["d", identifier],
            ["title", title]
        ]
        if let description {
            tags.append(["description", description])
        }
        let pTags = authorIDs.map { ["p", $0] }
        tags.append(contentsOf: pTags)
        
        return JSONEvent(
            pubKey: pubKey,
            kind: .followSet,
            tags: tags,
            content: ""
        )
    }
}
