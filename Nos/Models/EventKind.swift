/// The kind of a nostr event. This can be used to map from the integer representing a kind to its meaning.
/// - Note: Be careful not to add kinds we don't support yet. When we're parsing event JSON, we reject event kinds
///         that aren't defined here, and we *want* to reject any kinds we don't actually support.
/// - Note: See [Event Kinds](https://github.com/nostr-protocol/nips?tab=readme-ov-file#event-kinds) for details.
public enum EventKind: Int64, CaseIterable, Hashable {
    /// User Metadata
    case metaData = 0

    /// Short Text Note
    case text = 1

    /// Follow List
    case contactList = 3

    /// Encrypted Direct Message
    case directMessage = 4

    /// Event Deletion
    case delete = 5

    /// Repost
    case repost = 6

    /// Reaction
    case like = 7

    /// Seal
    case seal = 13

    /// Direct Message
    case directMessageRumor = 14
    
    /// Picture Post (NIP-68)
    case picturePost = 20

    /// Channel Message
    case channelMessage = 42

    /// Request to Vanish
    case requestToVanish = 62

    /// Gift Wrap
    case giftWrap = 1059

    /// Report
    case report = 1984

    /// Label
    case label = 1985

    /// Notification Service Registration
    case notificationServiceRegistration = 6666

    /// Zap Request
    case zapRequest = 9734

    /// Zap Receipt
    case zapReceipt = 9735

    // swiftlint:disable number_separator

    /// Mute List
    case mute = 10000

    /// NIP-42 Relay Authentication
    case relayAuth = 22242

    /// NIP-98 HTTP Authentication
    case httpAuth = 27235

    /// NIP-51 Follow Set
    case followSet = 30000

    /// Long-form Content
    case longFormContent = 30023
    

    // swiftlint:enable number_separator
}
