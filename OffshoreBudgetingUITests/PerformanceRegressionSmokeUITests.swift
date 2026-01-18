import XCTest

final class PerformanceRegressionSmokeUITests: XCTestCase {
    private let cardID = "B51F1C5D-3FD7-4C5F-BBBE-8B5A6F5D8F70"

    private func waitForSeedDone(in app: XCUIApplication, timeout: TimeInterval = 20, file: StaticString = #file, line: UInt = #line) {
        let marker = app.staticTexts["uitest_seed_done"]
        XCTAssertTrue(marker.waitForExistence(timeout: timeout), "Seed did not complete", file: file, line: line)
    }

    private func firstById(_ id: String, in app: XCUIApplication, timeout: TimeInterval = 8, file: StaticString = #file, line: UInt = #line) -> XCUIElement {
        let anyMatch = app.descendants(matching: .any).matching(identifier: id).firstMatch
        if anyMatch.waitForExistence(timeout: timeout) {
            return anyMatch
        }
        let candidates = [
            app.cells[id].firstMatch,
            app.otherElements[id].firstMatch,
            app.buttons[id].firstMatch,
            app.staticTexts[id].firstMatch
        ]
        for element in candidates {
            if element.waitForExistence(timeout: timeout) {
                return element
            }
        }
        XCTFail("Element not found: \(id)\n\(app.debugDescription)", file: file, line: line)
        return anyMatch
    }

    private func scrollToElement(_ element: XCUIElement, in app: XCUIApplication, timeout: TimeInterval = 8) {
        let start = Date()
        while !element.isHittable && Date().timeIntervalSince(start) < timeout {
            if app.tables.firstMatch.exists {
                app.tables.firstMatch.swipeUp()
            } else if app.scrollViews.firstMatch.exists {
                app.scrollViews.firstMatch.swipeUp()
            } else {
                app.swipeUp()
            }
            if element.isHittable { break }
        }
    }

    private func launchApp(seed: String, startTab: String, enableExperimentalFixes: Bool) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launchEnvironment["UB_PERF"] = "1"
        app.launchEnvironment["UB_PERF_STDOUT"] = "1"
        if enableExperimentalFixes {
            app.launchEnvironment["UB_PERF_EXPERIMENT_NO_TAB_REMOUNT"] = "1"
            app.launchEnvironment["UB_PERF_EXPERIMENT_MOTION_REDUCE_RAW_PUBLISH"] = "1"
            app.launchEnvironment["UB_PERF_EXPERIMENT_MOTION_THROTTLE_HZ"] = "30"
            app.launchEnvironment["UB_PERF_EXPERIMENT_IMPORT_OFF_MAIN"] = "1"
        }
        app.launchEnvironment["UITEST_SKIP_ONBOARDING"] = "1"
        app.launchEnvironment["UITEST_RESET_STATE"] = "1"
        app.launchEnvironment["UITEST_DISABLE_ANIMATIONS"] = "1"
        app.launchEnvironment["UITEST_STORE"] = "memory"
        app.launchEnvironment["UITEST_RUN_ID"] = UUID().uuidString
        app.launchEnvironment["UITEST_LOCALE"] = "en_US"
        app.launchEnvironment["UITEST_TIMEZONE"] = "UTC"
        app.launchEnvironment["UITEST_SEED"] = seed
        app.launchEnvironment["UITEST_START_TAB"] = startTab
        app.launch()
        waitForSeedDone(in: app)
        return app
    }

    func testCards_toCardDetail_baseline() {
        runCardsToDetailScenario(enableExperimentalFixes: false)
    }

    func testCards_toCardDetail_withAllFixesEnabled() {
        runCardsToDetailScenario(enableExperimentalFixes: true)
    }

    private func runCardsToDetailScenario(enableExperimentalFixes: Bool) {
        let launchStart = Date()
        let app = launchApp(seed: "core_universe", startTab: "cards", enableExperimentalFixes: enableExperimentalFixes)
        let seedReadySeconds = Date().timeIntervalSince(launchStart)

        let cardRow = firstById("card_row_\(cardID)", in: app, timeout: 6)
        if cardRow.exists {
            scrollToElement(cardRow, in: app)
            cardRow.tap()
        } else {
            let tile = firstById("card_tile_\(cardID)", in: app, timeout: 6)
            scrollToElement(tile, in: app)
            tile.tap()
        }

        let detailStart = Date()
        XCTAssertTrue(firstById("card_details_screen", in: app, timeout: 12).exists)
        let detailVisibleSeconds = Date().timeIntervalSince(detailStart)

        // Back out to Cards to capture appear/disappear + transition rebuilds.
        let backButton = app.navigationBars.buttons.firstMatch
        if backButton.exists {
            backButton.tap()
        }

        let summary = """
        enableExperimentalFixes=\(enableExperimentalFixes)
        seedReadySeconds=\(String(format: "%.3f", seedReadySeconds))
        cardDetailVisibleSeconds=\(String(format: "%.3f", detailVisibleSeconds))
        """
        print("UB_PERF_SUMMARY\n\(summary)")
        XCTContext.runActivity(named: "Perf Summary") { activity in
            let attachment = XCTAttachment(string: summary)
            attachment.name = "Perf Summary"
            attachment.lifetime = .keepAlways
            activity.add(attachment)
        }
    }
}
