import XCTest

final class CoreScreensSmokeTests: XCTestCase {
    private let budgetID = "DCE9E4FD-4EC7-4EA1-9A67-1E5C3A3A8AA1"
    private let cardID = "B51F1C5D-3FD7-4C5F-BBBE-8B5A6F5D8F70"
    private let categoryID = "C8AFB4B9-5F10-4EB4-9C12-06D6E86B7C2B"
    private let plannedExpenseID = "8E6DCA5A-9D1C-4C91-85B9-A990C4B2E199"
    private let presetTemplateID = "6E71C8A6-2A7F-4F87-8D4A-4B3E7A3C1CC1"
    private let plannedIncomeID = "2D2072C4-2F80-4F32-9E7B-8A9D0D2F6B15"

    private func launchApp(seed: String, startTab: String? = nil, startRoute: String? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launchEnvironment["UITEST_SKIP_ONBOARDING"] = "1"
        app.launchEnvironment["UITEST_RESET_STATE"] = "1"
        app.launchEnvironment["UITEST_DISABLE_ANIMATIONS"] = "1"
        app.launchEnvironment["UITEST_STORE"] = "memory"
        app.launchEnvironment["UITEST_RUN_ID"] = UUID().uuidString
        app.launchEnvironment["UITEST_LOCALE"] = "en_US"
        app.launchEnvironment["UITEST_TIMEZONE"] = "UTC"
        app.launchEnvironment["UITEST_SEED"] = seed
        if let startTab {
            app.launchEnvironment["UITEST_START_TAB"] = startTab
        }
        if let startRoute {
            app.launchEnvironment["UITEST_START_ROUTE"] = startRoute
        }
        app.launch()
        waitForSeedDone(in: app)
        return app
    }

    private func waitForSeedDone(in app: XCUIApplication, file: StaticString = #file, line: UInt = #line) {
        let marker = app.staticTexts["uitest_seed_done"]
        XCTAssertTrue(marker.waitForExistence(timeout: 10), "Seed did not complete", file: file, line: line)
    }

    private func firstById(_ id: String, in app: XCUIApplication, timeout: TimeInterval = 5, file: StaticString = #file, line: UInt = #line) -> XCUIElement {
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

    private func findElement(in app: XCUIApplication, identifier: String, timeout: TimeInterval = 5, file: StaticString = #file, line: UInt = #line) -> XCUIElement {
        return firstById(identifier, in: app, timeout: timeout, file: file, line: line)
    }

    private func scrollToElement(_ element: XCUIElement, in app: XCUIApplication, timeout: TimeInterval = 6) {
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
            if app.tables.firstMatch.exists {
                app.tables.firstMatch.swipeDown()
            } else if app.scrollViews.firstMatch.exists {
                app.scrollViews.firstMatch.swipeDown()
            } else {
                app.swipeDown()
            }
        }
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
        let fallback = firstById(id, in: app, timeout: 5, file: file, line: line)
        if fallback.exists {
            fallback.tap()
        } else {
            XCTFail("Tab not found: \(id)", file: file, line: line)
        }
    }

    private func waitForBudgetsList(in app: XCUIApplication, file: StaticString = #file, line: UInt = #line) {
        if app.navigationBars["Budgets"].waitForExistence(timeout: 8) { return }
        let addButton = app.buttons["Add Budget"].firstMatch
        XCTAssertTrue(addButton.waitForExistence(timeout: 8), "Budgets list not visible", file: file, line: line)
    }

    private func waitForBudgetDetails(in app: XCUIApplication, file: StaticString = #file, line: UInt = #line) {
        if app.buttons["budget_overflow_menu"].firstMatch.waitForExistence(timeout: 8) { return }
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 8), "Budget details not visible", file: file, line: line)
    }

    private func waitForPresets(in app: XCUIApplication, file: StaticString = #file, line: UInt = #line) {
        if app.navigationBars["Presets"].waitForExistence(timeout: 8) { return }
        XCTAssertTrue(app.buttons["Add Preset Planned Expense"].firstMatch.waitForExistence(timeout: 8), "Presets not visible", file: file, line: line)
    }

    private func ensureBudgetPlannedSegment(in app: XCUIApplication) {
        let plannedButton = app.segmentedControls.buttons["Planned"].firstMatch
        if plannedButton.exists {
            plannedButton.tap()
        }
    }

    private func ensureCardPlannedSegment(in app: XCUIApplication) {
        let plannedButton = app.segmentedControls.buttons["Planned"].firstMatch
        if plannedButton.exists {
            plannedButton.tap()
        }
    }

    private func dismissTipsOverlayIfPresent(in app: XCUIApplication) {
        let closeButton = app.buttons["xmark"].firstMatch
        if closeButton.exists {
            closeButton.tap()
        } else if app.buttons["Continue"].firstMatch.exists {
            app.buttons["Continue"].firstMatch.tap()
        }
    }

    private func waitForDisappearance(_ element: XCUIElement, timeout: TimeInterval = 6, file: StaticString = #file, line: UInt = #line) {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(result, .completed, "Expected element to disappear", file: file, line: line)
    }

    private func clearAndType(_ element: XCUIElement, text: String) {
        element.tap()
        if let current = element.value as? String {
            let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count)
            element.typeText(deleteString)
        }
        element.typeText(text)
    }

    func testBudgets_deleteBudget_updatesUI_andNavigatesBack() {
        let app = launchApp(seed: "core_universe", startTab: "budgets")

        waitForBudgetsList(in: app)

        let budgetRowID = "budget_row_\(budgetID)"
        let budgetRow = findElement(in: app, identifier: budgetRowID)
        scrollToElement(budgetRow, in: app)
        XCTAssertTrue(budgetRow.exists)
        budgetRow.tap()

        waitForBudgetDetails(in: app)

        let overflowMenu = app.buttons["budget_overflow_menu"].firstMatch
        XCTAssertTrue(overflowMenu.waitForExistence(timeout: 5))
        overflowMenu.tap()

        let deleteButton = firstById("budget_delete_button", in: app, timeout: 5)
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 5))
        deleteButton.tap()

        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        let confirmDelete = alert.buttons["Delete"].firstMatch
        XCTAssertTrue(confirmDelete.waitForExistence(timeout: 5))
        confirmDelete.tap()

        waitForBudgetsList(in: app)
        waitForDisappearance(budgetRow)
        XCTAssertFalse(app.otherElements["budget_row_untitled"].exists)
    }

    func testBudgetExpenses_deletedFromCardDetail_doNotReappearInBudgetDetails() {
        let app = launchApp(seed: "core_universe", startTab: "budgets")

        let budgetRowID = "budget_row_\(budgetID)"
        let budgetRow = findElement(in: app, identifier: budgetRowID)
        scrollToElement(budgetRow, in: app)
        XCTAssertTrue(budgetRow.exists)
        budgetRow.tap()

        waitForBudgetDetails(in: app)

        let plannedRowID = "planned_row_\(plannedExpenseID)"
        ensureBudgetPlannedSegment(in: app)
        let plannedRow = firstById(plannedRowID, in: app, timeout: 8)
        scrollToElement(plannedRow, in: app)
        XCTAssertTrue(plannedRow.exists)

        tapTab("tab_cards", in: app)

        let cardRowID = "card_row_\(cardID)"
        let cardRow = firstById(cardRowID, in: app, timeout: 5)
        if !cardRow.exists {
            let tileRow = firstById("card_tile_\(cardID)", in: app, timeout: 5)
            scrollToElement(tileRow, in: app)
            XCTAssertTrue(tileRow.exists)
            tileRow.tap()
        } else {
            scrollToElement(cardRow, in: app)
            XCTAssertTrue(cardRow.exists)
            cardRow.tap()
        }

        let cardDetails = firstById("card_details_screen", in: app, timeout: 8)
        XCTAssertTrue(cardDetails.waitForExistence(timeout: 8))
        dismissTipsOverlayIfPresent(in: app)
        ensureCardPlannedSegment(in: app)

        let cardExpenseRowID = "card_expense_row_\(plannedExpenseID)"
        let cardExpenseRow = firstById(cardExpenseRowID, in: app, timeout: 8)
        scrollToElement(cardExpenseRow, in: app)
        XCTAssertTrue(cardExpenseRow.exists)
        cardExpenseRow.swipeLeft()

        let swipeDelete = app.buttons["swipe_delete"].firstMatch
        XCTAssertTrue(swipeDelete.waitForExistence(timeout: 5))
        swipeDelete.tap()

        let alert = app.alerts.firstMatch
        if alert.waitForExistence(timeout: 5) {
            let confirmDelete = alert.buttons["Delete"].firstMatch
            if confirmDelete.waitForExistence(timeout: 5) {
                confirmDelete.tap()
            }
        }

        waitForDisappearance(cardExpenseRow)

        tapTab("tab_budgets", in: app)

        if !app.buttons["budget_overflow_menu"].firstMatch.waitForExistence(timeout: 5) {
            waitForBudgetsList(in: app)
            let budgetRowAgain = findElement(in: app, identifier: budgetRowID)
            scrollToElement(budgetRowAgain, in: app)
            XCTAssertTrue(budgetRowAgain.exists)
            budgetRowAgain.tap()
        }
        waitForBudgetDetails(in: app)
        ensureBudgetPlannedSegment(in: app)
        let plannedRowAfter = app.descendants(matching: .any).matching(identifier: plannedRowID).firstMatch
        waitForDisappearance(plannedRowAfter)
    }

    func testCategories_CRUD_refresh() {
        let app = launchApp(seed: "core_universe", startRoute: "categories")

        let addButton = app.buttons["categories_add_button"].firstMatch
        XCTAssertTrue(addButton.waitForExistence(timeout: 8))

        let rowID = "category_row_id_\(categoryID)"
        let categoryRow = findElement(in: app, identifier: rowID)
        scrollToElement(categoryRow, in: app)
        XCTAssertTrue(categoryRow.exists)
        categoryRow.swipeLeft()

        let deleteSwipe = app.buttons["swipe_delete"].firstMatch
        XCTAssertTrue(deleteSwipe.waitForExistence(timeout: 2))
        deleteSwipe.tap()

        let alert = app.alerts.firstMatch
        if alert.waitForExistence(timeout: 5) {
            if alert.buttons["Delete Category & Expenses"].exists {
                alert.buttons["Delete Category & Expenses"].tap()
            } else if alert.buttons["Delete"].exists {
                alert.buttons["Delete"].tap()
            }
        }

        waitForDisappearance(categoryRow)
    }

    func testIncome_CRUD_refresh() {
        let app = launchApp(seed: "core_universe", startTab: "income")

        let incomeRowID = "row_income_\(plannedIncomeID)"
        let incomeRow = findElement(in: app, identifier: incomeRowID)
        scrollToElement(incomeRow, in: app)
        XCTAssertTrue(incomeRow.exists)
        incomeRow.swipeLeft()

        let swipeEdit = app.buttons["swipe_edit"].firstMatch
        XCTAssertTrue(swipeEdit.waitForExistence(timeout: 5))
        swipeEdit.tap()

        let amountField = app.textFields["txt_income_amount"].firstMatch
        XCTAssertTrue(amountField.waitForExistence(timeout: 5))
        clearAndType(amountField, text: "1234")

        let confirm = app.buttons["btn_confirm"].firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        confirm.tap()

        let incomeRowAfter = findElement(in: app, identifier: incomeRowID)
        scrollToElement(incomeRowAfter, in: app)
        XCTAssertTrue(incomeRowAfter.exists)

        incomeRowAfter.swipeLeft()
        XCTAssertTrue(swipeEdit.waitForExistence(timeout: 5))
        swipeEdit.tap()

        XCTAssertTrue(amountField.waitForExistence(timeout: 5))
        let value = (amountField.value as? String) ?? ""
        XCTAssertTrue(value.contains("1234"))

        let cancel = app.buttons["Cancel"].firstMatch
        if cancel.waitForExistence(timeout: 5) {
            cancel.tap()
        }
    }

    func testPresets_basicVisibility_orCRUD_if_supported() {
        let app = launchApp(seed: "core_universe", startTab: "settings")

        let presetsNav = firstById("nav_manage_presets", in: app, timeout: 8)
        XCTAssertTrue(presetsNav.waitForExistence(timeout: 8))
        presetsNav.tap()

        waitForPresets(in: app)

        let presetRowID = "preset_row_\(presetTemplateID)"
        let presetRow = findElement(in: app, identifier: presetRowID)
        scrollToElement(presetRow, in: app)
        XCTAssertTrue(presetRow.exists)
    }
}
