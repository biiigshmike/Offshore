//
//  IncomeSmokeUITests.swift
//  OffshoreBudgetingUITests
//

import XCTest

final class IncomeSmokeUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-ui-testing"]
        app.launchEnvironment["UITEST_RESET_STATE"] = "1"
        app.launchEnvironment["UITEST_SKIP_ONBOARDING"] = "1"
        app.launchEnvironment["UITEST_START_TAB"] = "income"
        app.launchEnvironment["UITEST_DISABLE_ANIMATIONS"] = "1"
        app.launchEnvironment["UITEST_SEED"] = "empty"
        app.launch()
    }

    func testAddAndDeleteIncome() {
        // Add income using stable IDs
        let addButton = app.buttons["btn_add_income"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        let source = app.textFields["txt_income_source"]
        XCTAssertTrue(source.waitForExistence(timeout: 5))
        source.tap(); source.typeText("Paycheck")

        let amount = app.textFields["txt_income_amount"]
        XCTAssertTrue(amount.waitForExistence(timeout: 5))
        amount.tap(); amount.typeText("123.45")

        let confirm = app.buttons["btn_confirm"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        confirm.tap()

        // Verify row exists via label
        let rowTitle = app.staticTexts["Paycheck"]
        XCTAssertTrue(rowTitle.waitForExistence(timeout: 5))

        // Delete via dedicated test toolbar button
        let deleteFirst = app.buttons["btn_delete_first_income"]
        XCTAssertTrue(deleteFirst.waitForExistence(timeout: 5))
        deleteFirst.tap()

        // Verify empty state appears
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'No income for'"))
                        .firstMatch.waitForExistence(timeout: 5))
    }
}
