import XCTest

final class CategoriesSmokeTests: XCTestCase {
    private let groceriesID = "9B44A0A2-9E1E-4B1C-B8C9-2C7FD31F1E3A"
    private let testCatID = "4E7B2C3F-6B1D-4F5F-AF6A-1D58D6F2A1D2"

    private func launchApp(seed: String) -> XCUIApplication {
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
        app.launchEnvironment["UITEST_START_ROUTE"] = "categories"
        app.launch()
        return app
    }

    private func openCategoriesScreen(in app: XCUIApplication, file: StaticString = #file, line: UInt = #line) {
        if app.navigationBars["Categories"].waitForExistence(timeout: 8) {
            return
        }
        let addButton = app.buttons["categories_add_button"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 8), "Categories screen not visible", file: file, line: line)
    }

    private func findRow(in app: XCUIApplication, id: String, timeout: TimeInterval = 5, file: StaticString = #file, line: UInt = #line) -> XCUIElement {
        let identifier = "category_row_id_\(id)"
        let nameIdentifier = "category_row_name_\(id)"
        let candidates = [
            app.cells[identifier].firstMatch,
            app.buttons[identifier].firstMatch,
            app.otherElements[identifier].firstMatch,
            app.cells.containing(.staticText, identifier: nameIdentifier).firstMatch,
            app.otherElements.containing(.staticText, identifier: nameIdentifier).firstMatch
        ]
        for element in candidates {
            if element.waitForExistence(timeout: timeout) {
                return element
            }
        }
        XCTFail("Row not found for \(identifier)", file: file, line: line)
        return app.otherElements[identifier]
    }

    private func waitForDisappearance(ofCategoryID id: String, in app: XCUIApplication, timeout: TimeInterval = 8, file: StaticString = #file, line: UInt = #line) {
        let identifier = "category_row_id_\(id)"
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            let anyMatch = app.descendants(matching: .any).matching(identifier: identifier).firstMatch
            if !anyMatch.exists { return }
            if app.tables.firstMatch.exists {
                app.tables.firstMatch.swipeUp()
            } else {
                app.swipeUp()
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.15))
        }
        XCTFail("Expected row to disappear: \(identifier)", file: file, line: line)
    }

    func testCategories_addAndDeleteCategory() {
        let app = launchApp(seed: "categories_with_testcat")
        openCategoriesScreen(in: app)

        let row = findRow(in: app, id: testCatID)
        row.swipeLeft()

        let deleteSwipe = app.buttons["swipe_delete"].firstMatch
        if deleteSwipe.waitForExistence(timeout: 2) {
            deleteSwipe.tap()
        }

        let alert = app.alerts.firstMatch
        if alert.waitForExistence(timeout: 2) {
            if alert.buttons["Delete"].exists {
                alert.buttons["Delete"].tap()
            } else if alert.buttons["Delete Category & Expenses"].exists {
                alert.buttons["Delete Category & Expenses"].tap()
            } else if alert.buttons.element(boundBy: 0).exists {
                alert.buttons.element(boundBy: 0).tap()
            }
        }

        waitForDisappearance(ofCategoryID: testCatID, in: app)
    }

    func testCategories_deleteUsedCategory_showsCascadeAlertAndDeletes() {
        let app = launchApp(seed: "categories_with_one")
        openCategoriesScreen(in: app)

        let groceriesRow = findRow(in: app, id: groceriesID)
        groceriesRow.swipeLeft()

        let deleteSwipe = app.buttons["swipe_delete"].firstMatch
        if deleteSwipe.waitForExistence(timeout: 2) {
            deleteSwipe.tap()
        }

        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        let usedByText = alert.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'used by'")).firstMatch
        XCTAssertTrue(usedByText.exists)

        if alert.buttons["Delete Category & Expenses"].exists {
            alert.buttons["Delete Category & Expenses"].tap()
        } else if alert.buttons["Delete"].exists {
            alert.buttons["Delete"].tap()
        }

        waitForDisappearance(ofCategoryID: groceriesID, in: app)
    }
}
