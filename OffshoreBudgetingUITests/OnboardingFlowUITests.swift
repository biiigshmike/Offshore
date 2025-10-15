import XCTest

final class OnboardingFlowUITests: XCTestCase {
    private let bundleIdentifier = "com.mbrown.offshore"
    private let syncCardThemesKey = "syncCardThemes"
    private let syncBudgetPeriodKey = "syncBudgetPeriod"
    private let defaultTimeout: TimeInterval = 10

    private var defaults: UserDefaults!

    override func setUpWithError() throws {
        continueAfterFailure = false
        defaults = try XCTUnwrap(UserDefaults(suiteName: bundleIdentifier))
        defaults.removePersistentDomain(forName: bundleIdentifier)
        defaults.synchronize()
    }

    func testOnboardingFlowCreatesDataAndPersists() throws {
        let categoryName = "Groceries"
        let cardName = "Launch Card"
        let presetName = "Utility"
        let plannedAmount = "120"

        var app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launchEnvironment["UITEST_RESET_STATE"] = "1"
        app.launch()

        startOnboarding(in: app)
        addCategory(in: app, name: categoryName)
        advanceFromOnboardingStep(in: app)

        addCard(in: app, name: cardName)
        advanceFromOnboardingStep(in: app)

        addPreset(in: app, name: presetName, amount: plannedAmount, cardName: cardName, categoryName: categoryName)
        toggleCloudSync(in: app)
        advanceFromOnboardingStep(in: app)

        assertHomeVisible(in: app)

        app.terminate()

        app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()

        assertHomeVisible(in: app)
        assertPersistedDataVisible(in: app, categoryName: categoryName, cardName: cardName, presetName: presetName)
    }
}

private extension OnboardingFlowUITests {
    func startOnboarding(in app: XCUIApplication) {
        let getStartedButton = app.buttons["Get Started"]
        XCTAssertTrue(getStartedButton.waitForExistence(timeout: defaultTimeout))
        getStartedButton.tap()
    }

    func addCategory(in app: XCUIApplication, name: String) {
        let addCategoryButton = app.buttons["Add Category"]
        XCTAssertTrue(addCategoryButton.waitForExistence(timeout: defaultTimeout))
        addCategoryButton.tap()

        let nameField = app.textFields["Shopping"]
        XCTAssertTrue(nameField.waitForExistence(timeout: defaultTimeout))
        nameField.tap()
        nameField.typeText(name)

        let saveButton = app.buttons["Save"].firstMatch
        XCTAssertTrue(saveButton.waitForExistence(timeout: defaultTimeout))
        saveButton.tap()

        let categoryLabel = app.staticTexts[name]
        XCTAssertTrue(categoryLabel.waitForExistence(timeout: defaultTimeout))
    }

    func addCard(in app: XCUIApplication, name: String) {
        let addCardButton = app.buttons["Add Card"]
        XCTAssertTrue(addCardButton.waitForExistence(timeout: defaultTimeout))
        addCardButton.tap()

        let nameField = app.textFields["Card Name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: defaultTimeout))
        nameField.tap()
        nameField.typeText(name)

        let createButton = app.buttons["Create Card"]
        XCTAssertTrue(createButton.waitForExistence(timeout: defaultTimeout))
        createButton.tap()

        let cardTile = app.buttons[name]
        XCTAssertTrue(cardTile.waitForExistence(timeout: defaultTimeout))
    }

    func addPreset(in app: XCUIApplication, name: String, amount: String, cardName: String, categoryName: String) {
        let addPresetButton = app.buttons["Add Preset Planned Expense"]
        XCTAssertTrue(addPresetButton.waitForExistence(timeout: defaultTimeout))
        addPresetButton.tap()

        let descriptionField = app.textFields["Expense Description"]
        XCTAssertTrue(descriptionField.waitForExistence(timeout: defaultTimeout))
        descriptionField.tap()
        descriptionField.typeText(name)

        let amountField = app.textFields["Planned Amount"]
        XCTAssertTrue(amountField.waitForExistence(timeout: defaultTimeout))
        amountField.tap()
        amountField.typeText(amount)

        let cardTile = app.buttons[cardName]
        if cardTile.waitForExistence(timeout: defaultTimeout) {
            cardTile.tap()
        }

        let categoryChip = app.buttons[categoryName]
        if categoryChip.waitForExistence(timeout: defaultTimeout) {
            categoryChip.tap()
        }

        let saveButton = app.buttons["Save"].firstMatch
        XCTAssertTrue(saveButton.waitForExistence(timeout: defaultTimeout))
        saveButton.tap()

        let presetRow = app.staticTexts[name]
        XCTAssertTrue(presetRow.waitForExistence(timeout: defaultTimeout))
    }

    func toggleCloudSync(in app: XCUIApplication) {
        let cloudSyncSwitch = app.switches["Enable Cloud Sync"]
        XCTAssertTrue(cloudSyncSwitch.waitForExistence(timeout: defaultTimeout))
        if let value = cloudSyncSwitch.value as? String, value == "0" {
            cloudSyncSwitch.tap()
        }

        XCTAssertTrue(waitForDefaultsValue(key: syncCardThemesKey, expected: true))
        XCTAssertTrue(waitForDefaultsValue(key: syncBudgetPeriodKey, expected: true))
    }

    func advanceFromOnboardingStep(in app: XCUIApplication) {
        let doneButton = app.buttons["Done"].firstMatch
        XCTAssertTrue(doneButton.waitForExistence(timeout: defaultTimeout))
        doneButton.tap()
    }

    func assertHomeVisible(in app: XCUIApplication) {
        let homeNavBar = app.navigationBars["Home"]
        XCTAssertTrue(homeNavBar.waitForExistence(timeout: defaultTimeout))
    }

    func assertPersistedDataVisible(in app: XCUIApplication, categoryName: String, cardName: String, presetName: String) {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: defaultTimeout))

        tabBar.buttons["Cards"].tap()
        XCTAssertTrue(app.buttons[cardName].waitForExistence(timeout: defaultTimeout))

        tabBar.buttons["Presets"].tap()
        XCTAssertTrue(app.staticTexts[presetName].waitForExistence(timeout: defaultTimeout))

        tabBar.buttons["Settings"].tap()
        let manageCategoriesRow = app.staticTexts["Manage Categories"]
        XCTAssertTrue(manageCategoriesRow.waitForExistence(timeout: defaultTimeout))
        manageCategoriesRow.tap()

        let categoryCell = app.staticTexts[categoryName]
        XCTAssertTrue(categoryCell.waitForExistence(timeout: defaultTimeout))
    }

    func waitForDefaultsValue(key: String, expected: Bool, timeout: TimeInterval = 5) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if defaults.bool(forKey: key) == expected {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
        return defaults.bool(forKey: key) == expected
    }
}
