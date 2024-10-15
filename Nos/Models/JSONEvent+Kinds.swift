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
        // Append client tag so we can detect if Nos overwrites a user's contact list.
        // https://github.com/planetary-social/cleanstr/issues/51
        tags.append(["client", "nos", "https://nos.social"])
        
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
}
