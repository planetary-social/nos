/// The source to be used for a feed of notes.
enum FeedSource: RawRepresentable, Hashable, Equatable {
    case following
    case relay(host: String, description: String?)
    case list(name: String, description: String?)
    
    var displayName: String {
        switch self {
        case .following: String(localized: "following")
        case .relay(let name, _), .list(let name, _): name
        }
    }
    
    var description: String? {
        switch self {
        case .following: nil
        case .relay(_, let description), .list(_, let description): description
        }
    }
    
    static func == (lhs: FeedSource, rhs: FeedSource) -> Bool {
        switch (lhs, rhs) {
        case (.following, .following): true
        case (.relay(let name1, _), .relay(let name2, _)): name1 == name2
        case (.list(let name1, _), .list(let name2, _)): name1 == name2
        default: false
        }
    }
    
    // Note: RawRepresentable conformance is required for use of @AppStorage for persistence.
    var rawValue: String {
        switch self {
        case .following:
            "following"
        case .relay(let host, let description):
            "relay:|\(host):|\(description ?? "")"
        case .list(let name, let description):
            "list:|\(name):|\(description ?? "")"
        }
    }
    
    init?(rawValue: String) {
        let components = rawValue.split(separator: ":|").map { String($0) }
        guard let caseName = components.first else {
            return nil
        }
        
        switch caseName {
        case "following":
            self = .following
        case "relay":
            guard components.count >= 2 else {
                return nil
            }
            let description = components.count >= 3 ? components[2] : ""
            self = .relay(host: components[1], description: description)
        case "list":
            guard components.count >= 2 else {
                return nil
            }
            let description = components.count >= 3 ? components[2] : ""
            self = .list(name: components[1], description: description)
        default:
            return nil
        }
    }
}
