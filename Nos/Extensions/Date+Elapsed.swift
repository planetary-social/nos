//
//  Date+Elapsed.swift
//  FBTT
//
//  Created by Christoph on 8/6/19.
//  Copyright © 2019 Verse Communications Inc. All rights reserved.
//

import Foundation

extension Date {

    func distanceFromNowString() -> String {

        // from and to dates
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        let from = calendar.dateComponents([.timeZone, .minute, .hour, .day, .month, .year], from: self)
        let to = calendar.dateComponents([.timeZone, .minute, .hour, .day, .month, .year], from: Date())

        // TODO https://app.asana.com/0/914798787098068/1148032440727609/f
        // TODO this is off by one hour during the daylight savings switch (for 24 hours only)
        // compute delta
        let delta = calendar.dateComponents([.timeZone, .minute, .hour, .day], from: from, to: to)
        let minutes = abs(delta.minute ?? 0)
        let hours = abs(delta.hour ?? 0)
        let day = abs(delta.day ?? 0)

        switch day {
        case 0:
            // at least 1 minute ago
            if hours == 0 { return "\(max(1, minutes))m" }

            // at least 1 hour ago
            else { return "\(hours)h" }

        // 1 to 7 days ago
        case 1..<7:
            return "\(day)d"

        // more than a week, less than a year
        case 7..<365:
            let formatter = DateFormatter()
            formatter.timeStyle = .none
            formatter.dateFormat = "MMMM dd"
            return formatter.string(from: self)
            
        // at least 1 year ago
        default:
            let formatter = DateFormatter()
            formatter.timeStyle = .none
            formatter.dateFormat = "MMMM dd, YYYY"
            return formatter.string(from: self)
        }
    }
}
