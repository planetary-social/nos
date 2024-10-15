import Foundation

/// Options for expiring messages - each of these represents a length of time before a message expires.
enum ExpirationTimeOption: Double, Identifiable, CaseIterable {
    
    // Raw value is the number of seconds until this message expires
    case oneHour = 3600
    case oneDay = 86_400
    case sevenDays = 604_800
    case oneYear = 31_536_000 
    
    var id: TimeInterval {
        rawValue
    }
    
    // The text that will be displayed at the top of a button representing this option.
    var topText: String {
        switch self {
        case .oneHour:
            return "1"
        case .oneDay:
            return "24"
        case .sevenDays:
            return "7"
        case .oneYear:
            return "365"
        }
    }
    
    // The text that will be displayed below `topText`, representing the unit of time this option uses.
    var unit: String {
        switch self {
        case .oneHour:
            return String(localized: "hourAbbreviated")
        case .oneDay:
            return String(localized: "hoursAbbreviated")
        case .sevenDays:
            return String(localized: "daysAbbreviated")
        case .oneYear:
            return String(localized: "daysAbbreviated")
        }
    }
    
    var timeInterval: TimeInterval {
        rawValue
    }
    
    var accessibilityLabel: String {
        "\(topText) \(unit)"
    }
}
