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
    
    /// An event that represents a picture-first post (NIP-68).
    /// - Parameters:
    ///   - pubKey: The public key of the event creator.
    ///   - title: The title of the post.
    ///   - description: The description/content of the post.
    ///   - imageMetadata: Array of image metadata including URLs and attributes.
    ///   - tags: Additional tags like content warnings, location, etc.
    /// - Returns: The ``JSONEvent`` representing the picture post.
    static func picturePost(
        pubKey: String,
        title: String,
        description: String,
        imageMetadata: [[String]],
        tags: [[String]] = []
    ) -> JSONEvent {
        var allTags = [["title", title]]
        allTags.append(contentsOf: imageMetadata)
        allTags.append(contentsOf: tags)
        
        return JSONEvent(
            pubKey: pubKey,
            kind: .picturePost,
            tags: allTags,
            content: description
        )
    }
    
    /// Creates an event that represents a video post (NIP-71).
    /// - Parameters:
    ///   - pubKey: The public key of the event creator.
    ///   - title: The title of the video.
    ///   - description: A summary or description of the video content.
    ///   - isShortForm: If true, creates a short video event (kind 22), otherwise a normal video event (kind 21).
    ///   - publishedAt: Optional Unix timestamp (in seconds) when the video was first published.
    ///   - duration: Optional duration of the video in seconds.
    ///   - videoMetadata: An array of "imeta" tags describing the video sources, dimensions, preview images, etc.
    ///     Each imeta tag should be an array where the first element is "imeta" and remaining elements describe the video:
    ///     - Example: ["imeta", "url https://example.com/video.mp4", "m video/mp4", "x 1280", "y 720"]
    ///   - contentWarning: Optional warning regarding the video content.
    ///   - altText: Optional accessibility description for the video.
    ///   - tags: Additional tags (e.g. text-track, segment, hashtags, participants, reference links) to include.
    /// - Returns: A JSONEvent representing the video post.
    static func videoPost(
        pubKey: String,
        title: String,
        description: String,
        isShortForm: Bool = false,
        publishedAt: Int? = nil,
        duration: Int? = nil,
        videoMetadata: [[String]],
        contentWarning: String? = nil,
        altText: String? = nil,
        tags: [[String]] = []
    ) -> JSONEvent {
        var allTags = [["title", title]]
        
        if let publishedAt {
            allTags.append(["published_at", String(publishedAt)])
        }
        
        if let duration {
            allTags.append(["duration", String(duration)])
        }
        
        // Append the video-specific metadata (imeta tags) – these carry the URL, dimensions, preview images, etc.
        allTags.append(contentsOf: videoMetadata)
        
        if let contentWarning {
            allTags.append(["content-warning", contentWarning])
        }
        
        if let altText {
            allTags.append(["alt", altText])
        }
        
        // Append any additional tags provided.
        allTags.append(contentsOf: tags)
        
        return JSONEvent(
            pubKey: pubKey,
            kind: isShortForm ? .shortVideo : .video,
            tags: allTags,
            content: description
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
