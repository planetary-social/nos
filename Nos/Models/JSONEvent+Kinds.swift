import Foundation

extension JSONEvent {
    
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
