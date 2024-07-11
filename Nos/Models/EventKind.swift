/// The kind of a nostr event. This can be used to map from the integer representing a kind to its meaning.
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

    /// Channel Message
    case channelMessage = 42

    /// Gift Wrap
    case giftWrap = 1059

    /// Report
    case report = 1984

    /// Label
    case label = 1985

    /// Notification Service Registration
    case notificationServiceRegistration = 6666

    /// Mute List
    case mute = 10_000

    /// HTTP Auth
    case auth = 27_235

    /// Long-form Content
    case longFormContent = 30_023

    /// Live Event
    case liveEvent = 30_311

    /// Custom Feed
    case feed = 31_890
}
