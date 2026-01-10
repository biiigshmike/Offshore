import XCTest

final class HomeViewSmokeTests: XCTestCase {
    private func launchApp(
        seed: String? = nil,
        store: String = "memory",
        resetState: Bool = true,
        startTab: String? = "home",
        sizeCategory: String? = nil,
        storePath: String? = nil
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launchEnvironment["UITEST_SKIP_ONBOARDING"] = "1"
        app.launchEnvironment["UITEST_RESET_STATE"] = resetState ? "1" : "0"
        app.launchEnvironment["UITEST_DISABLE_ANIMATIONS"] = "1"
        app.launchEnvironment["UITEST_STORE"] = store
        app.launchEnvironment["UITEST_LOCALE"] = "en_US"
        app.launchEnvironment["UITEST_TIMEZONE"] = "UTC"
        if let storePath {
            app.launchEnvironment["UITEST_STORE_PATH"] = storePath
        }
        if let seed {
            app.launchEnvironment["UITEST_SEED"] = seed
        }
        if let startTab {
            app.launchEnvironment["UITEST_START_TAB"] = startTab
        }
        if let sizeCategory {
            app.launchEnvironment["UITEST_SIZE_CATEGORY"] = sizeCategory
        }
        app.launch()
        if seed != nil {
            waitForSeedDone(in: app)
        }
        return app
    }

    private func waitForSeedDone(in app: XCUIApplication, file: StaticString = #file, line: UInt = #line) {
        let marker = app.staticTexts["uitest_seed_done"]
        XCTAssertTrue(marker.waitForExistence(timeout: 10), "Seed did not complete", file: file, line: line)
    }

    private func tapTab(_ id: String, in app: XCUIApplication, file: StaticString = #file, line: UInt = #line) {
        let tabButton = app.tabBars.buttons[id]
        if tabButton.exists {
            tabButton.tap()
            return
        }
        let labelFallback = id.replacingOccurrences(of: "tab_", with: "").capitalized
        let labeledTab = app.tabBars.buttons[labelFallback]
        if labeledTab.exists {
            labeledTab.tap()
            return
        }
        XCTFail("Tab not found: \(id)", file: file, line: line)
    }

    private func scrollUntilExists(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int = 12) {
        if element.exists { return }
        for _ in 0..<maxSwipes {
            if element.exists { return }
            if app.tables.firstMatch.exists {
                app.tables.firstMatch.swipeUp()
            } else if app.scrollViews.firstMatch.exists {
                app.scrollViews.firstMatch.swipeUp()
            } else {
                app.swipeUp()
            }
        }
    }

    private func clearAndType(_ element: XCUIElement, text: String) {
        element.tap()
        if let current = element.value as? String {
            let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count)
            element.typeText(deleteString)
        }
        element.typeText(text)
    }

    private func elementByLabel(_ label: String, in app: XCUIApplication) -> XCUIElement {
        let predicate = NSPredicate(format: "label == %@", label)
        return app.descendants(matching: .any).matching(predicate).firstMatch
    }

    private func waitForHomeContent(in app: XCUIApplication, file: StaticString = #file, line: UInt = #line) {
        let deadline = Date().addingTimeInterval(14)
        while Date() < deadline {
            let incomeLabel = elementByLabel("Actual Income", in: app)
            let widgetsHeader = elementByLabel("Widgets", in: app)
            if incomeLabel.exists || widgetsHeader.exists {
                return
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
        XCTFail("Home content did not load", file: file, line: line)
    }

    private func tapSettingsRow(_ label: String, in app: XCUIApplication, file: StaticString = #file, line: UInt = #line) {
        let cell = app.cells.containing(.staticText, identifier: label).firstMatch
        if cell.exists {
            cell.tap()
            return
        }
        let other = app.otherElements.containing(.staticText, identifier: label).firstMatch
        if other.exists {
            other.tap()
            return
        }
        let fallback = elementByLabel(label, in: app)
        XCTAssertTrue(fallback.waitForExistence(timeout: 6), "Missing settings row: \(label)", file: file, line: line)
        fallback.tap()
    }

    private func selectPeriod(_ name: String, in app: XCUIApplication, file: StaticString = #file, line: UInt = #line) {
        let presetsButton = app.buttons["Date presets"].firstMatch
        XCTAssertTrue(presetsButton.waitForExistence(timeout: 6), "Date presets button missing", file: file, line: line)
        presetsButton.tap()
        let option = app.buttons[name].firstMatch
        XCTAssertTrue(option.waitForExistence(timeout: 6), "Missing period option: \(name)", file: file, line: line)
        option.tap()
    }

    private func assertIncomeValues(actual: String, planned: String, in app: XCUIApplication, file: StaticString = #file, line: UInt = #line) {
        let actualLabel = app.staticTexts["Actual Income"].firstMatch
        XCTAssertTrue(actualLabel.waitForExistence(timeout: 6), "Actual Income label missing", file: file, line: line)
        let actualValue = app.staticTexts[actual].firstMatch
        XCTAssertTrue(actualValue.waitForExistence(timeout: 6), "Missing actual income value \(actual)", file: file, line: line)
        let plannedLabel = app.staticTexts["Planned Income"].firstMatch
        XCTAssertTrue(plannedLabel.waitForExistence(timeout: 6), "Planned Income label missing", file: file, line: line)
        let plannedValue = app.staticTexts[planned].firstMatch
        XCTAssertTrue(plannedValue.waitForExistence(timeout: 6), "Missing planned income value \(planned)", file: file, line: line)
    }

    private func editWidgetsButton(in app: XCUIApplication) -> XCUIElement {
        let labeled = elementByLabel("Edit widgets", in: app)
        if labeled.exists { return labeled }
        let fallback = elementByLabel("Edit", in: app)
        if fallback.exists { return fallback }
        return app.otherElements["Edit"].firstMatch
    }

    private func doneEditingButton(in app: XCUIApplication) -> XCUIElement {
        let labeled = elementByLabel("Done editing widgets", in: app)
        if labeled.exists { return labeled }
        let fallback = elementByLabel("Done", in: app)
        if fallback.exists { return fallback }
        return app.otherElements["Done"].firstMatch
    }

    private func tapEditWidgetsButton(in app: XCUIApplication, file: StaticString = #file, line: UInt = #line) {
        let edit = editWidgetsButton(in: app)
        XCTAssertTrue(edit.waitForExistence(timeout: 8), "Edit widgets button missing", file: file, line: line)
        if edit.isHittable {
            edit.tap()
        } else {
            edit.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
    }

    private func tapDoneEditingButton(in app: XCUIApplication, file: StaticString = #file, line: UInt = #line) {
        let done = doneEditingButton(in: app)
        XCTAssertTrue(done.waitForExistence(timeout: 8), "Done editing button missing", file: file, line: line)
        if done.isHittable {
            done.tap()
        } else {
            done.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
    }

    private func widgetTitle(_ name: String, in app: XCUIApplication) -> XCUIElement {
        let labeled = elementByLabel(name, in: app)
        if labeled.exists { return labeled }
        return app.staticTexts[name].firstMatch
    }

    private func dragWidget(_ source: XCUIElement, to target: XCUIElement) {
        let start = source.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let end = target.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        start.press(forDuration: 0.6, thenDragTo: end)
    }

    private func waitForFrameChange(of element: XCUIElement, initialMinY: CGFloat, file: StaticString = #file, line: UInt = #line) -> Bool {
        let predicate = NSPredicate { _, _ in
            element.frame.minY != initialMinY
        }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: 4)
        return result == .completed
    }

    private func attemptWidgetReorder(_ first: XCUIElement, _ second: XCUIElement, in app: XCUIApplication) -> Bool {
        scrollUntilExists(first, in: app)
        scrollUntilExists(second, in: app)
        guard first.exists, second.exists else { return false }
        let isFirstAbove = first.frame.minY < second.frame.minY
        let source = isFirstAbove ? second : first
        let target = isFirstAbove ? first : second
        let initialSourceMinY = source.frame.minY
        dragWidget(source, to: target)
        return waitForFrameChange(of: source, initialMinY: initialSourceMinY)
    }

    private func waitForDisappearance(_ element: XCUIElement, timeout: TimeInterval = 8, file: StaticString = #file, line: UInt = #line) {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(result, .completed, "Expected element to disappear", file: file, line: line)
    }

    private func waitForReconfigureOverlayIfNeeded(in app: XCUIApplication) {
        let overlay = app.staticTexts["Reconfiguring storage…"].firstMatch
        if overlay.exists {
            waitForDisappearance(overlay)
        }
    }

    func testHome_multipleBudgetPeriods_switchingUpdatesWidgets() {
        let app = launchApp(seed: HomeViewSeedData.seedMultiBudget)

        selectPeriod("Monthly", in: app)
        assertIncomeValues(
            actual: HomeViewSeedData.monthlyIncomeActual,
            planned: HomeViewSeedData.monthlyIncomePlanned,
            in: app
        )

        selectPeriod("Quarterly", in: app)
        assertIncomeValues(
            actual: HomeViewSeedData.quarterlyIncomeActual,
            planned: HomeViewSeedData.quarterlyIncomePlanned,
            in: app
        )

        selectPeriod("Yearly", in: app)
        assertIncomeValues(
            actual: HomeViewSeedData.yearlyIncomeActual,
            planned: HomeViewSeedData.yearlyIncomePlanned,
            in: app
        )
    }

    func testHome_noBudget_thenCreateBudget_refreshesWidgets() {
        let app = launchApp(seed: HomeViewSeedData.seedNoBudget)

        XCTAssertTrue(app.staticTexts["No budget data yet."].waitForExistence(timeout: 6))
        XCTAssertFalse(app.staticTexts["Widgets"].exists)

        tapTab("tab_budgets", in: app)
        let addBudget = app.buttons["Add Budget"].firstMatch
        XCTAssertTrue(addBudget.waitForExistence(timeout: 6))
        addBudget.tap()

        let nameField = app.textFields["Budget Name"].firstMatch
        XCTAssertTrue(nameField.waitForExistence(timeout: 6))
        clearAndType(nameField, text: "Home Seed Budget")

        let cardToggle = app.switches[HomeViewSeedData.legacyCardName].firstMatch
        if cardToggle.waitForExistence(timeout: 3), (cardToggle.value as? String) == "0" {
            cardToggle.tap()
        }

        let presetToggle = app.switches[HomeViewSeedData.globalPresetName].firstMatch
        if presetToggle.waitForExistence(timeout: 3), (presetToggle.value as? String) == "0" {
            presetToggle.tap()
        }

        let createButton = app.buttons["Create Budget"].firstMatch
        XCTAssertTrue(createButton.waitForExistence(timeout: 6))
        createButton.tap()

        XCTAssertTrue(addBudget.waitForExistence(timeout: 8))

        tapTab("tab_home", in: app)
        XCTAssertTrue(app.staticTexts["Actual Income"].waitForExistence(timeout: 8))
        XCTAssertFalse(app.staticTexts["No budget data yet."].exists)
        XCTAssertFalse(app.staticTexts["Untitled Budget"].exists)
    }

    func testHome_widgetOrder_persistsAcrossRelaunch() {
        let storePath = NSTemporaryDirectory() + "offshore-homeview-persist.sqlite"
        let app = launchApp(seed: HomeViewSeedData.seedMultiBudget, store: "temp", storePath: storePath)

        waitForHomeContent(in: app)
        tapEditWidgetsButton(in: app)

        let income = widgetTitle("Income", in: app)
        let savings = widgetTitle("Savings Outlook", in: app)
        XCTAssertTrue(income.exists)
        XCTAssertTrue(savings.exists)

        let incomeAboveSavings = income.frame.minY < savings.frame.minY
        let didMove = attemptWidgetReorder(income, savings, in: app)

        let reorderedIncomeAboveSavings = income.frame.minY < savings.frame.minY
        if didMove {
            XCTAssertNotEqual(incomeAboveSavings, reorderedIncomeAboveSavings)
        } else {
            XCTAssertEqual(incomeAboveSavings, reorderedIncomeAboveSavings)
        }

        tapDoneEditingButton(in: app)

        tapEditWidgetsButton(in: app)
        XCTAssertEqual(reorderedIncomeAboveSavings, income.frame.minY < savings.frame.minY)

        app.terminate()

        let relaunched = launchApp(seed: nil, store: "temp", resetState: false, storePath: storePath)
        waitForHomeContent(in: relaunched)
        tapEditWidgetsButton(in: relaunched)

        let relaunchIncome = widgetTitle("Income", in: relaunched)
        let relaunchSavings = widgetTitle("Savings Outlook", in: relaunched)
        XCTAssertEqual(reorderedIncomeAboveSavings, relaunchIncome.frame.minY < relaunchSavings.frame.minY)
    }

    func testHome_cloudSyncToggle_localOnlyWidgetOrder() {
        let app = launchApp(seed: HomeViewSeedData.seedMultiBudget, store: "temp")

        tapTab("tab_settings", in: app)
        tapSettingsRow("iCloud", in: app)

        let cloudToggle = app.switches["Enable iCloud Sync"].firstMatch
        XCTAssertTrue(cloudToggle.waitForExistence(timeout: 8))
        if (cloudToggle.value as? String) == "0" {
            cloudToggle.tap()
            waitForReconfigureOverlayIfNeeded(in: app)
        }

        let widgetToggle = app.switches["Sync Home Widgets Across Devices"].firstMatch
        XCTAssertTrue(widgetToggle.waitForExistence(timeout: 6))
        if (widgetToggle.value as? String) == "0" {
            widgetToggle.tap()
        }

        cloudToggle.tap()
        let confirmKeep = app.alerts.buttons["Switch to Local (Keep Data)"].firstMatch
        if confirmKeep.waitForExistence(timeout: 6) {
            confirmKeep.tap()
            waitForReconfigureOverlayIfNeeded(in: app)
        }

        XCTAssertEqual(cloudToggle.value as? String, "0")
        XCTAssertEqual(widgetToggle.value as? String, "0")
        XCTAssertFalse(widgetToggle.isEnabled)

        tapTab("tab_home", in: app)
        waitForHomeContent(in: app)
        tapEditWidgetsButton(in: app)

        let income = widgetTitle("Income", in: app)
        let savings = widgetTitle("Savings Outlook", in: app)
        let incomeAboveSavings = income.frame.minY < savings.frame.minY
        let didMove = attemptWidgetReorder(income, savings, in: app)

        tapDoneEditingButton(in: app)
        tapEditWidgetsButton(in: app)
        let reorderedIncomeAboveSavings = income.frame.minY < savings.frame.minY
        if didMove {
            XCTAssertNotEqual(incomeAboveSavings, reorderedIncomeAboveSavings)
        } else {
            XCTAssertEqual(incomeAboveSavings, reorderedIncomeAboveSavings)
        }
    }

    func testHome_cloudSyncEnabled_doesNotBreakWidgets() {
        let app = launchApp(seed: HomeViewSeedData.seedMultiBudget, store: "temp")

        tapTab("tab_settings", in: app)
        tapSettingsRow("iCloud", in: app)

        let cloudToggle = app.switches["Enable iCloud Sync"].firstMatch
        XCTAssertTrue(cloudToggle.waitForExistence(timeout: 8))
        if (cloudToggle.value as? String) == "0" {
            cloudToggle.tap()
            waitForReconfigureOverlayIfNeeded(in: app)
        }

        tapTab("tab_home", in: app)
        XCTAssertTrue(app.staticTexts["Actual Income"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["No budget data yet."].exists)
    }

    func testHome_dynamicType_accessibilitySmoke() {
        let app = launchApp(
            seed: HomeViewSeedData.seedMultiBudget,
            store: "memory",
            sizeCategory: "axxxl"
        )

        let presetsButton = app.buttons["Date presets"].firstMatch
        XCTAssertTrue(presetsButton.waitForExistence(timeout: 6))
        XCTAssertTrue(presetsButton.isHittable)

        let editButton = editWidgetsButton(in: app)
        XCTAssertTrue(editButton.waitForExistence(timeout: 6))

        let incomeTitle = widgetTitle("Income", in: app)
        scrollUntilExists(incomeTitle, in: app)
        XCTAssertTrue(incomeTitle.exists)
        XCTAssertTrue(app.staticTexts["Actual Income"].exists)
    }
}
