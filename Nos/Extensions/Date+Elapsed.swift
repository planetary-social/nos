import Foundation

extension Date {

    /// Formats the date into a localized human-readable string, relative to a given end date and calendar.
    ///
    /// If the distance between the dates is one year or more, a long date format is returned.
    ///
    /// If the distance between the dates is one week or more and less than one year,
    /// a date with a fully spelled out month and day is returned.
    ///
    /// If the distance between the dates is one day or more and less than one week,
    /// an abbreviated representation of number of days between the dates is returned.
    ///
    /// If the distance between the dates is one hour or more and less than one day,
    /// an abbreviated representation of number of hours between the dates is returned.
    ///
    /// If none of the above cases apply, an abbreviated representation of
    /// number of minutes between the dates is returned.
    ///
    /// If there is less than 1 minute in distance between the dates, the abbreviated representation
    /// is pinned to 1 minute.
    ///
    /// If there are any unexpected issues formatting the distance between dates in the above cases,
    /// a long date format is returned as a fallback.
    ///
    /// The default value of `endDate` is `Date.now` and the default value of `calendar` is `Calendar.current`.
    /// Normally, these values should not need to be provided. They are exposed for unit testing.
    ///
    /// - Parameters:
    ///   - endDate: The end date to use to calculate distance from this date.
    ///   - calendar: The calendar to use when formatting the human-readable string
    /// - Returns:.The localized human-readable string of this date relative to the end date.
    func distanceString(_ endDate: Date = Date.now, calendar: Calendar = Calendar.current) -> String {
        let unitFlags: NSCalendar.Unit = [.minute, .hour, .day, .weekOfMonth, .year]

        let components = (calendar as NSCalendar).components(unitFlags, from: self, to: endDate, options: [])

        if let year = components.year, year >= 1 {
            return formatLongDate(calendar)
        }

        if let week = components.weekOfMonth, week >= 1 {
            let dateFormatter = DateFormatter()
            dateFormatter.timeStyle = .none
            dateFormatter.dateFormat = DateFormatter.dateFormat(
                fromTemplate: "MMMMd",
                options: 0,
                locale: calendar.locale
            )
            dateFormatter.calendar = calendar
            dateFormatter.locale = calendar.locale
            dateFormatter.timeZone = calendar.timeZone
            return dateFormatter.string(from: self)
        }

        let dateComponentsFormatter = DateComponentsFormatter()
        dateComponentsFormatter.unitsStyle = .abbreviated
        dateComponentsFormatter.maximumUnitCount = 1
        dateComponentsFormatter.allowedUnits = unitFlags

        if let day = components.day, day >= 1, let formattedDate =
            dateComponentsFormatter.string(from: DateComponents(calendar: calendar, day: day)) {
            return formattedDate
        }

        if let hour = components.hour, hour >= 1, let formattedDate =
            dateComponentsFormatter.string(from: DateComponents(calendar: calendar, hour: hour)) {
            return formattedDate
        }

        if let minute = components.minute {
            if minute >= 1 {
                let dateComponents = DateComponents(calendar: calendar, minute: max(1, minute))
                if let formattedDate = dateComponentsFormatter.string(from: dateComponents) {
                    return formattedDate
                }
            } else {
                return String(localized: "now")
            }
        }

        return formatLongDate(calendar)
    }

    /// Formats the date in a long date format with the given calendar and with time omitted.
    /// - Parameters:
    ///   - calendar: The calendar to use when formatting the date.
    private func formatLongDate(_ calendar: Calendar) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .none
        dateFormatter.dateStyle = .long
        dateFormatter.calendar = calendar
        dateFormatter.locale = calendar.locale
        dateFormatter.timeZone = calendar.timeZone
        return dateFormatter.string(from: self)
    }
}
