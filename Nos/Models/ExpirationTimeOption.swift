//
//  ExpirationTimeOption.swift
//  Nos
//
//  Created by Matthew Lorentz on 5/5/23.
//

import Foundation

enum ExpirationTimeOption: Double, Identifiable, CaseIterable {
    
    // Raw value is the number of seconds until this message expires
    case fifteenMins = 900
    case oneHour = 3600
    case oneDay = 86_400
    case sevenDays = 604_800
    
    var id: TimeInterval {
        rawValue
    }
    
    var topText: String {
        switch self {
        case .fifteenMins:
            return "15"
        case .oneHour:
            return "1"
        case .oneDay:
            return "24"
        case .sevenDays:
            return "7"
        }
    }
    
    var unit: String {
        switch self {
        case .fifteenMins:
            return "min"
        case .oneHour:
            return "hour"
        case .oneDay:
            return "hours"
        case .sevenDays:
            return "days"
        }
    }
    
    var timeInterval: TimeInterval {
        rawValue
    }
}
