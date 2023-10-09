//
//  ExpirationTimeOption.swift
//  Nos
//
//  Created by Matthew Lorentz on 5/5/23.
//

import Foundation

/// Options for expiring messages - each of these represents a length of time before a message expires.
enum ExpirationTimeOption: Double, Identifiable, CaseIterable {
    
    // Raw value is the number of seconds until this message expires
    case oneHour            = 3600
    case oneDay             = 86_400
    case sevenDays          = 604_800
    case oneMonth           = 13_149_000
    case oneYear            = 31_536_000

    
    var id: TimeInterval {
        rawValue
    }
    

    
    // The text that will be displayed below `topText`, representing the unit of time this option uses.
    var unit: String {
        switch self {
        case .oneHour:
            return Localized.hour.string
        case .oneDay:
            return Localized.day.string
        case .sevenDays:
            return Localized.week.string
        case .oneMonth:
            return Localized.month.string
        case .oneYear:
            return Localized.year.string
        }
    }
    
    var timeInterval: TimeInterval {
        rawValue
    }
    
    var accessibilityLabel: String {
        "\(unit)"
    }
}
