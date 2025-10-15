import Foundation
import XCTest

// MARK: - OffshoreBudgetingUITests
final class OffshoreBudgetingUITests: XCTestCase {

    // MARK: Properties
    private var app: XCUIApplication!
    private lazy var currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()

    // MARK: XCTest Lifecycle
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["--uitest-reset", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Tests
    func testOnboardingIncomeAndBudgetFlow() throws {
        try completeOnboarding()
        capture("home-after-onboarding")

        try addIncome(source: "Salary", amount: 1000, isPlanned: true)
        try addIncome(source: "Bonus", amount: 250, isPlanned: false)
        verifyIncomeTotals(planned: 1000, actual: 250, plannedSource: "Salary", actualSource: "Bonus")
        capture("income-summary")

        navigateBackToHome()
        createCurrentPeriodBudget(named: "Primary Budget")
        createNextPeriodBudget(named: "Future Budget")
        returnToCurrentPeriod()

        addPlannedExpense(description: "Rent", planned: 1200, actual: 1100, category: "Housing")
        addVariableExpense(description: "Dinner", amount: 75, category: "Dining")
        verifyHomeMetrics(
            plannedActual: 1100,
            variable: 75,
            potentialIncome: 1000,
            actualIncome: 250
        )
        capture("home-after-expenses")
    }

    // MARK: - Onboarding
    private func completeOnboarding() throws {
        let getStarted = app.buttons["Get Started"]
        XCTAssertTrue(getStarted.waitForExistence(timeout: 10))
        getStarted.tap()

        try addCategory(named: "Housing")
        try addCategory(named: "Dining")
        tapOnboardingButton(titled: "Done")

        try addPrimaryCard(named: "Main Card")
        tapOnboardingButton(titled: "Done")

        try addOnboardingPreset()
        tapOnboardingButton(titled: "Done")

        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))
    }

    private func addCategory(named name: String) throws {
        let navBar = app.navigationBars["Categories"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 5))

        let addButton = navBar.buttons["Add Category"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 3))
        addButton.tap()

        let sheetNav = app.navigationBars["New Category"]
        XCTAssertTrue(sheetNav.waitForExistence(timeout: 5))

        let textField = app.textFields.element(boundBy: 0)
        XCTAssertTrue(textField.waitForExistence(timeout: 5))
        clearAndType(textField, text: name)

        let saveButton = sheetNav.buttons["Save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 2))
        saveButton.tap()
        XCTAssertFalse(sheetNav.waitForExistence(timeout: 5))
    }

    private func addPrimaryCard(named name: String) throws {
        let navBar = app.navigationBars["Cards"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 5))

        let addButton = navBar.buttons["Add Card"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 3))
        addButton.tap()

        let sheetNav = app.navigationBars["Add Card"]
        XCTAssertTrue(sheetNav.waitForExistence(timeout: 5))

        let nameField = app.textFields["Card Name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        clearAndType(nameField, text: name)

        let saveButton = sheetNav.buttons["Create Card"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 2))
        saveButton.tap()
        XCTAssertFalse(sheetNav.waitForExistence(timeout: 5))
    }

    private func addOnboardingPreset() throws {
        let navBar = app.navigationBars["Presets"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 5))

        let addButton = navBar.buttons["Add Preset Planned Expense"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 3))
        addButton.tap()

        let sheetNav = app.navigationBars["Add Planned Expense"]
        XCTAssertTrue(sheetNav.waitForExistence(timeout: 5))

        let cardButton = app.buttons["Main Card"]
        XCTAssertTrue(cardButton.waitForExistence(timeout: 5))
        cardButton.tap()

        if app.buttons["Housing"].waitForExistence(timeout: 2) {
            app.buttons["Housing"].tap()
        }

        let descriptionField = app.textFields["Expense Description"]
        XCTAssertTrue(descriptionField.waitForExistence(timeout: 5))
        clearAndType(descriptionField, text: "Utilities")

        let plannedField = app.textFields["Planned Amount"]
        XCTAssertTrue(plannedField.waitForExistence(timeout: 5))
        clearAndType(plannedField, text: entryString(for: 120))

        let actualField = app.textFields["Actual Amount"]
        XCTAssertTrue(actualField.waitForExistence(timeout: 5))
        clearAndType(actualField, text: entryString(for: 100))

        let saveButton = sheetNav.buttons["Save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 2))
        saveButton.tap()
        XCTAssertFalse(sheetNav.waitForExistence(timeout: 5))
    }

    private func tapOnboardingButton(titled title: String) {
        let button = app.buttons[title].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        button.tap()
    }

    // MARK: - Income
    private func addIncome(source: String, amount: Double, isPlanned: Bool) throws {
        app.tabBars.buttons["Income"].tap()

        let addButton = app.navigationBars["Income"].buttons["Add Income"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        let sheetNav = app.navigationBars["Add Income"]
        XCTAssertTrue(sheetNav.waitForExistence(timeout: 5))

        if !isPlanned {
            let segmented = app.segmentedControls["incomeTypeSegmentedControl"]
            XCTAssertTrue(segmented.waitForExistence(timeout: 2))
            segmented.buttons["Actual"].tap()
        }

        let sourceField = app.textFields["Income Source"]
        XCTAssertTrue(sourceField.waitForExistence(timeout: 5))
        clearAndType(sourceField, text: source)

        let amountField = app.textFields["Income Amount"]
        XCTAssertTrue(amountField.waitForExistence(timeout: 5))
        clearAndType(amountField, text: entryString(for: amount))

        let saveButton = sheetNav.buttons["Add Income"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 2))
        saveButton.tap()
        XCTAssertFalse(sheetNav.waitForExistence(timeout: 5))
    }

    private func verifyIncomeTotals(planned: Double, actual: Double, plannedSource: String, actualSource: String) {
        let plannedString = currencyString(for: planned)
        let actualString = currencyString(for: actual)

        XCTAssertTrue(app.staticTexts[plannedSource].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts[actualSource].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts[plannedString].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts[actualString].waitForExistence(timeout: 5))

        XCTAssertTrue(app.staticTexts["Week Total Income"].exists)
        XCTAssertTrue(app.staticTexts[plannedString].exists)
        XCTAssertTrue(app.staticTexts[actualString].exists)
    }

    private func navigateBackToHome() {
        app.tabBars.buttons["Home"].tap()
    }

    // MARK: - Budgets
    private func createCurrentPeriodBudget(named name: String) {
        openEllipsisMenu()
        tapMenuOption(named: "Create Budget")

        let sheetNav = app.navigationBars["Add Budget"]
        XCTAssertTrue(sheetNav.waitForExistence(timeout: 5))

        if let nameField = sheetNav.textFields.allElementsBoundByIndex.first, nameField.exists {
            clearAndType(nameField, text: name)
        }

        enableToggleOrCheckbox(named: "Main Card")

        let saveButton = sheetNav.buttons["Create Budget"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 2))
        saveButton.tap()
        XCTAssertFalse(sheetNav.waitForExistence(timeout: 5))
    }

    private func createNextPeriodBudget(named name: String) {
        moveToNextPeriod()
        openEllipsisMenu()
        tapMenuOption(named: "Create Budget")

        let sheetNav = app.navigationBars["Add Budget"]
        XCTAssertTrue(sheetNav.waitForExistence(timeout: 5))

        if let nameField = sheetNav.textFields.allElementsBoundByIndex.first, nameField.exists {
            clearAndType(nameField, text: name)
        }

        enableToggleOrCheckbox(named: "Main Card")

        let saveButton = sheetNav.buttons["Create Budget"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 2))
        saveButton.tap()
        XCTAssertFalse(sheetNav.waitForExistence(timeout: 5))
    }

    private func returnToCurrentPeriod() {
        let backButton = app.buttons["chevron.left"].firstMatch
        XCTAssertTrue(backButton.waitForExistence(timeout: 5))
        backButton.tap()
    }

    private func moveToNextPeriod() {
        let nextButton = app.buttons["chevron.right"].firstMatch
        XCTAssertTrue(nextButton.waitForExistence(timeout: 5))
        nextButton.tap()
    }

    private func openEllipsisMenu() {
        let navBar = app.navigationBars["Home"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 5))
        let candidates = ["ellipsis", "More", "more", "Menu"]
        if let button = candidates.compactMap({ identifier -> XCUIElement? in
            let element = navBar.buttons[identifier]
            return element.exists ? element : nil
        }).first {
            button.tap()
            return
        }

        let fallbackButton = navBar.buttons.allElementsBoundByIndex.last
        XCTAssertNotNil(fallbackButton, "Expected at least one navigation bar button")
        fallbackButton?.tap()
    }

    private func tapMenuOption(named title: String) {
        if app.buttons[title].waitForExistence(timeout: 2) {
            app.buttons[title].tap()
        } else if app.menuItems[title].waitForExistence(timeout: 2) {
            app.menuItems[title].tap()
        } else {
            XCTFail("Menu option \(title) not found")
        }
    }

    private func enableToggleOrCheckbox(named title: String) {
        if app.switches[title].exists {
            let toggle = app.switches[title]
            if let value = toggle.value as? String, value == "0" {
                toggle.tap()
            }
        } else if app.buttons[title].exists {
            let button = app.buttons[title]
            if let value = button.value as? String, value == "0" || value == "false" {
                button.tap()
            } else if !button.isSelected {
                button.tap()
            }
        }
    }

    // MARK: - Expenses
    private func addPlannedExpense(description: String, planned: Double, actual: Double, category: String) {
        openAddMenu()
        tapMenuOption(named: "Add Planned Expense")

        let sheetNav = app.navigationBars["Add Planned Expense"]
        XCTAssertTrue(sheetNav.waitForExistence(timeout: 5))

        let cardButton = app.buttons["Main Card"]
        XCTAssertTrue(cardButton.waitForExistence(timeout: 5))
        cardButton.tap()

        if app.buttons[category].waitForExistence(timeout: 2) {
            app.buttons[category].tap()
        }

        let descriptionField = app.textFields["Expense Description"]
        XCTAssertTrue(descriptionField.waitForExistence(timeout: 5))
        clearAndType(descriptionField, text: description)

        let plannedField = app.textFields["Planned Amount"]
        XCTAssertTrue(plannedField.waitForExistence(timeout: 5))
        clearAndType(plannedField, text: entryString(for: planned))

        let actualField = app.textFields["Actual Amount"]
        XCTAssertTrue(actualField.waitForExistence(timeout: 5))
        clearAndType(actualField, text: entryString(for: actual))

        let saveButton = sheetNav.buttons["Save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 2))
        saveButton.tap()
        XCTAssertFalse(sheetNav.waitForExistence(timeout: 5))
    }

    private func addVariableExpense(description: String, amount: Double, category: String) {
        openAddMenu()
        tapMenuOption(named: "Add Variable Expense")

        let sheetNav = app.navigationBars["Add Variable Expense"]
        XCTAssertTrue(sheetNav.waitForExistence(timeout: 5))

        let cardButton = app.buttons["Main Card"]
        XCTAssertTrue(cardButton.waitForExistence(timeout: 5))
        cardButton.tap()

        if app.buttons[category].waitForExistence(timeout: 2) {
            app.buttons[category].tap()
        }

        let descriptionField = app.textFields["Expense Description"]
        XCTAssertTrue(descriptionField.waitForExistence(timeout: 5))
        clearAndType(descriptionField, text: description)

        let amountField = app.textFields["Amount"]
        if amountField.exists {
            clearAndType(amountField, text: entryString(for: amount))
        } else if app.textFields["Expense Amount"].exists {
            clearAndType(app.textFields["Expense Amount"], text: entryString(for: amount))
        } else if let field = app.textFields.allElementsBoundByIndex.first {
            clearAndType(field, text: entryString(for: amount))
        }

        let saveButton = sheetNav.buttons["Save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 2))
        saveButton.tap()
        XCTAssertFalse(sheetNav.waitForExistence(timeout: 5))
    }

    private func openAddMenu() {
        let navBar = app.navigationBars["Home"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 5))
        let candidates = ["plus", "Add", "add"]
        if let button = candidates.compactMap({ identifier -> XCUIElement? in
            let element = navBar.buttons[identifier]
            return element.exists ? element : nil
        }).first {
            button.tap()
            return
        }

        let fallbackButton = navBar.buttons.allElementsBoundByIndex.first
        XCTAssertNotNil(fallbackButton, "Expected at least one navigation bar button")
        fallbackButton?.tap()
    }

    private func verifyHomeMetrics(plannedActual: Double, variable: Double, potentialIncome: Double, actualIncome: Double) {
        let plannedValue = currencyString(for: plannedActual)
        let variableValue = currencyString(for: variable)
        let potentialIncomeValue = currencyString(for: potentialIncome)
        let actualIncomeValue = currencyString(for: actualIncome)

        XCTAssertTrue(app.staticTexts[potentialIncomeValue].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts[actualIncomeValue].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts[plannedValue].waitForExistence(timeout: 5))

        if app.segmentedControls.buttons["Variable Expenses"].waitForExistence(timeout: 2) {
            app.segmentedControls.buttons["Variable Expenses"].tap()
        }

        XCTAssertTrue(app.staticTexts[variableValue].waitForExistence(timeout: 5))

        if app.segmentedControls.buttons["Planned Expenses"].exists {
            app.segmentedControls.buttons["Planned Expenses"].tap()
        }
    }

    // MARK: - Utilities
    private func clearAndType(_ element: XCUIElement, text: String) {
        element.tap()
        if let stringValue = element.value as? String, !stringValue.isEmpty {
            let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
            element.typeText(deleteString)
        }
        element.typeText(text)
    }

    private func entryString(for amount: Double) -> String {
        if amount.rounded() == amount {
            return String(Int(amount))
        }
        return String(format: "%.2f", amount)
    }

    private func currencyString(for amount: Double) -> String {
        currencyFormatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }

    private func capture(_ name: String) {
        let descriptor = deviceDescriptor()
        XCTContext.runActivity(named: "\(name)-\(descriptor)") { activity in
            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.lifetime = .keepAlways
            activity.add(attachment)
        }
    }

    private func deviceDescriptor() -> String {
        let environment = ProcessInfo.processInfo.environment
        if let deviceName = environment["SIMULATOR_DEVICE_NAME"], !deviceName.isEmpty {
            return deviceName.replacingOccurrences(of: " ", with: "_")
        }
        if let idiom = environment["TARGETED_DEVICE_FAMILY"], !idiom.isEmpty {
            return idiom
        }
        return "Device"
    }
}
