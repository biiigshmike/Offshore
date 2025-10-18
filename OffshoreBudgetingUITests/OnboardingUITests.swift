//
//  OnboardingUITests.swift
//  OffshoreBudgetingUITests
//

import XCTest

final class OnboardingUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-ui-testing"]
        // Reset but DO NOT skip onboarding in this test
        app.launchEnvironment["UITEST_RESET_STATE"] = "1"
        app.launch()
    }

    func testOnboardingFlowShowsTabs() {
        // Walk through onboarding
        let getStarted = app.buttons["Get Started"]
        if getStarted.waitForExistence(timeout: 5) { getStarted.tap() }

        let done = app.buttons["Done"]
        for _ in 0..<3 {
            XCTAssertTrue(done.waitForExistence(timeout: 5))
            done.tap()
        }

        // Loading step completes; verify we landed on Home by title or tab id
        let homeNav = app.navigationBars["Home"]
        let homeTab = app.buttons["tab_home"]
        XCTAssertTrue(homeNav.waitForExistence(timeout: 10) || homeTab.waitForExistence(timeout: 10))
    }
}
