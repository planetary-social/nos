//
//  NosPerformanceTests.swift
//  NosPerformanceTests
//
//  Created by Matthew Lorentz on 4/14/23.
//

import XCTest

final class NosPerformanceTests: XCTestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
    }

    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }

    func testScrollingAnimationPerformance() throws { 
        let app = XCUIApplication()
        app.launch()
        let homeFeed = app.scrollViews["home feed"]
            
        measure(metrics: [XCTOSSignpostMetric.scrollDecelerationMetric]) {
            homeFeed.swipeUp(velocity: .fast)
        }
    }
}
