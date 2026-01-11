import XCTest

final class OnboardingAndSecuritySmokeUITests: XCTestCase {
    private func launchApp(
        skipOnboarding: Bool,
        resetState: Bool,
        startTab: String? = nil,
        extraEnv: [String: String] = [:]
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launchEnvironment["UITEST_SKIP_ONBOARDING"] = skipOnboarding ? "1" : "0"
        app.launchEnvironment["UITEST_RESET_STATE"] = resetState ? "1" : "0"
        app.launchEnvironment["UITEST_DISABLE_ANIMATIONS"] = "1"
        if let startTab {
            app.launchEnvironment["UITEST_START_TAB"] = startTab
        }
        extraEnv.forEach { key, value in
            app.launchEnvironment[key] = value
        }
        app.launch()
        return app
    }

    private func waitForSwitchValueOn(
        _ element: XCUIElement,
        timeout: TimeInterval = 6,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let predicate = NSPredicate { object, _ in
            guard let element = object as? XCUIElement else { return false }
            if let numberValue = element.value as? NSNumber { return numberValue.intValue == 1 }
            if let stringValue = element.value as? String { return stringValue == "1" || stringValue == "On" }
            return false
        }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(result, .completed, "Switch did not reach ON value", file: file, line: line)
    }

    private func waitForSwitchReady(
        _ element: XCUIElement,
        timeout: TimeInterval = 6,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let predicate = NSPredicate(format: "exists == true AND isEnabled == true AND isHittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(result, .completed, "Switch did not become ready", file: file, line: line)
    }

    private func waitForMainUI(
        in app: XCUIApplication,
        timeout: TimeInterval = 8,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let homeScreen = app.otherElements["home_screen"]
        if homeScreen.waitForExistence(timeout: timeout) { return }
        let homeTab = app.tabBars.buttons["tab_home"].firstMatch
        if homeTab.waitForExistence(timeout: timeout) { return }
        let homeTabByTitle = app.tabBars.buttons["Home"].firstMatch
        XCTAssertTrue(homeTabByTitle.waitForExistence(timeout: timeout), "Main UI not visible", file: file, line: line)
    }
    
    private func tapSwitchOnRightEdge(_ element: XCUIElement) {
        let coordinate = element.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
        coordinate.tap()
    }

    func testAppLockToggleAndRelaunchGatesAccess() {
        let app = launchApp(
            skipOnboarding: true,
            resetState: true,
            startTab: "settings",
            extraEnv: [
                "UITEST_ALLOW_APP_LOCK": "1",
                "UITEST_DEVICE_AUTH_AVAILABLE": "1",
                "UITEST_DEVICE_AUTH_RESULT": "success"
            ]
        )

        let privacyRow = app.cells.staticTexts["Privacy"].firstMatch
        XCTAssertTrue(privacyRow.waitForExistence(timeout: 6))
        privacyRow.tap()

        let appLockToggle = app.switches["toggle_app_lock"]
        waitForSwitchReady(appLockToggle)
        tapSwitchOnRightEdge(appLockToggle)
        waitForSwitchValueOn(appLockToggle)



        let backButton = app.navigationBars.buttons["Settings"].firstMatch
        if backButton.exists {
            backButton.tap()
        }
        let homeTab = app.tabBars.buttons["tab_home"].firstMatch
        if homeTab.exists {
            homeTab.tap()
        }

        app.terminate()

        let relaunch = launchApp(
            skipOnboarding: true,
            resetState: false,
            startTab: "home",
            extraEnv: [
                "UITEST_ALLOW_APP_LOCK": "1",
                "UITEST_DEVICE_AUTH_AVAILABLE": "1",
                "UITEST_DEVICE_AUTH_RESULT": "failure"
            ]
        )

        let lockScreen = relaunch.otherElements["app_lock_screen"]
        XCTAssertTrue(lockScreen.waitForExistence(timeout: 8))
        XCTAssertFalse(relaunch.otherElements["home_screen"].exists)

        relaunch.terminate()

        let successRelaunch = launchApp(
            skipOnboarding: true,
            resetState: false,
            startTab: "home",
            extraEnv: [
                "UITEST_ALLOW_APP_LOCK": "1",
                "UITEST_DEVICE_AUTH_AVAILABLE": "1",
                "UITEST_DEVICE_AUTH_RESULT": "success"
            ]
        )

        let maybeLockScreen = successRelaunch.otherElements["app_lock_screen"]
        if maybeLockScreen.waitForExistence(timeout: 2) {
            let unlockButton = successRelaunch.buttons["btn_unlock"].firstMatch
            if unlockButton.waitForExistence(timeout: 2) {
                unlockButton.tap()
            }
        }

        waitForMainUI(in: successRelaunch)
    }

    func testCloudDecisionUseICloudDataSkipsOnboarding() {
        let app = launchApp(
            skipOnboarding: false,
            resetState: true,
            startTab: "home",
            extraEnv: [
                "UITEST_ENABLE_CLOUD_SYNC": "1",
                "UITEST_CLOUD_SYNC_AVAILABLE": "existing_data"
            ]
        )

        let alert = app.alerts["iCloud data found"].firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 6))
        alert.buttons["Use iCloud Data"].tap()

        waitForMainUI(in: app)
    }

    func testCloudDecisionStartFreshCompletesOnboarding() {
        let app = launchApp(
            skipOnboarding: false,
            resetState: true,
            startTab: "home",
            extraEnv: [
                "UITEST_ENABLE_CLOUD_SYNC": "1",
                "UITEST_CLOUD_SYNC_AVAILABLE": "existing_data"
            ]
        )

        let alert = app.alerts["iCloud data found"].firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 6))
        alert.buttons["Start Fresh"].tap()

        let onboarding = app.otherElements["onboarding_screen"]
        XCTAssertTrue(onboarding.waitForExistence(timeout: 6))

        let getStarted = app.buttons["Get Started"].firstMatch
        XCTAssertTrue(getStarted.waitForExistence(timeout: 6))
        getStarted.tap()

        for _ in 0..<3 {
            let done = app.buttons["Done"].firstMatch
            XCTAssertTrue(done.waitForExistence(timeout: 6))
            done.tap()
        }

        waitForMainUI(in: app)
    }
}
