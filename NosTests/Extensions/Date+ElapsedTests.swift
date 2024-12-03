import XCTest

final class Date_ElapsedTests: XCTestCase {

    // swiftlint:disable function_body_length
    func testDistanceStringDefaultLocale() throws {
        let locale = Locale(identifier: "en")
        var calendar = locale.calendar

        // Pin time zone to GMT to maintain consistency across runtime configurations on different machines.
        calendar.timeZone = TimeZone.gmt

        let date = try XCTUnwrap(
            DateComponents(calendar: calendar, year: 2023, month: 12, day: 9, hour: 3, minute: 8, second: 23)
                .date
        )

        XCTAssertEqual(date.distanceString(date, calendar: calendar), "now")
        XCTAssertEqual(date.addingTimeInterval(-2).distanceString(date, calendar: calendar), "now")
        XCTAssertEqual(date.addingTimeInterval(-3).distanceString(date, calendar: calendar), "now")
        XCTAssertEqual(date.addingTimeInterval(-59).distanceString(date, calendar: calendar), "now")
        XCTAssertEqual(date.addingTimeInterval(-60).distanceString(date, calendar: calendar), "1m")
        XCTAssertEqual(
            try XCTUnwrap(calendar.date(byAdding: .hour, value: -1, to: date))
                .addingTimeInterval(1)
                .distanceString(date, calendar: calendar),
            "59m"
        )
        XCTAssertEqual(
            try XCTUnwrap(calendar.date(byAdding: .hour, value: -1, to: date))
                .distanceString(date, calendar: calendar),
            "1h"
        )
        XCTAssertEqual(
            try XCTUnwrap(calendar.date(byAdding: .day, value: -1, to: date))
                .addingTimeInterval(1)
                .distanceString(date, calendar: calendar),
            "23h"
        )
        XCTAssertEqual(
            try XCTUnwrap(calendar.date(byAdding: .day, value: -1, to: date))
                .distanceString(date, calendar: calendar),
            "1d"
        )
        XCTAssertEqual(
            try XCTUnwrap(calendar.date(byAdding: .weekOfMonth, value: -1, to: date))
                .addingTimeInterval(1)
                .distanceString(date, calendar: calendar),
            "6d"
        )
        XCTAssertEqual(
            try XCTUnwrap(calendar.date(byAdding: .weekOfMonth, value: -1, to: date))
                .distanceString(date, calendar: calendar),
            "Dec 2"
        )
        XCTAssertEqual(
            try XCTUnwrap(calendar.date(byAdding: .month, value: -1, to: date))
                .distanceString(date, calendar: calendar),
            "Nov 9"
        )
        XCTAssertEqual(
            try XCTUnwrap(calendar.date(byAdding: .year, value: -1, to: date))
                .addingTimeInterval(1)
                .distanceString(date, calendar: calendar),
            "Dec 9"
        )
        XCTAssertEqual(
            try XCTUnwrap(calendar.date(byAdding: .year, value: -1, to: date))
                .distanceString(date, calendar: calendar),
            "Dec 9, 2022"
        )
        XCTAssertEqual(
            try XCTUnwrap(calendar.date(byAdding: .year, value: -2, to: date))
                .distanceString(date, calendar: calendar),
            "Dec 9, 2021"
        )
    }

    func testDistanceStringNonDefaultLocale() throws {
        let locale = Locale(identifier: "fr")
        var calendar = locale.calendar

        // Pin time zone to GMT to maintain consistency across runtime configurations on different machines.
        calendar.timeZone = TimeZone.gmt

        let date = try XCTUnwrap(
            DateComponents(calendar: calendar, year: 2023, month: 12, day: 9, hour: 3, minute: 8, second: 23)
                .date
        )

        XCTAssertEqual(date.distanceString(date, calendar: calendar), "now")
        XCTAssertEqual(date.addingTimeInterval(-2).distanceString(date, calendar: calendar), "now")
        XCTAssertEqual(date.addingTimeInterval(-3).distanceString(date, calendar: calendar), "now")
        XCTAssertEqual(date.addingTimeInterval(-59).distanceString(date, calendar: calendar), "now")
        XCTAssertEqual(date.addingTimeInterval(-60).distanceString(date, calendar: calendar), "1min")
        XCTAssertEqual(
            try XCTUnwrap(calendar.date(byAdding: .hour, value: -1, to: date))
                .addingTimeInterval(1)
                .distanceString(date, calendar: calendar),
            "59min"
        )
        XCTAssertEqual(
            try XCTUnwrap(calendar.date(byAdding: .hour, value: -1, to: date))
                .distanceString(date, calendar: calendar),
            "1h"
        )
        XCTAssertEqual(
            try XCTUnwrap(calendar.date(byAdding: .day, value: -1, to: date))
                .addingTimeInterval(1)
                .distanceString(date, calendar: calendar),
            "23h"
        )
        XCTAssertEqual(
            try XCTUnwrap(calendar.date(byAdding: .day, value: -1, to: date))
                .distanceString(date, calendar: calendar),
            "1j"
        )
        XCTAssertEqual(
            try XCTUnwrap(calendar.date(byAdding: .weekOfMonth, value: -1, to: date))
                .addingTimeInterval(1)
                .distanceString(date, calendar: calendar),
            "6j"
        )
        XCTAssertEqual(
            try XCTUnwrap(calendar.date(byAdding: .weekOfMonth, value: -1, to: date))
                .distanceString(date, calendar: calendar),
            "2 déc."
        )
        XCTAssertEqual(
            try XCTUnwrap(calendar.date(byAdding: .month, value: -1, to: date))
                .distanceString(date, calendar: calendar),
            "9 nov."
        )
        XCTAssertEqual(
            try XCTUnwrap(calendar.date(byAdding: .year, value: -1, to: date))
                .addingTimeInterval(1)
                .distanceString(date, calendar: calendar),
            "9 déc."
        )
        XCTAssertEqual(
            try XCTUnwrap(calendar.date(byAdding: .year, value: -1, to: date))
                .distanceString(date, calendar: calendar),
            "9 déc. 2022"
        )
        XCTAssertEqual(
            try XCTUnwrap(calendar.date(byAdding: .year, value: -2, to: date))
                .distanceString(date, calendar: calendar),
            "9 déc. 2021"
        )
    }
    // swiftlint:enable function_body_length
}
