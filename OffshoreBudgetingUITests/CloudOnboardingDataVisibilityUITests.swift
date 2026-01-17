import XCTest

final class CloudOnboardingDataVisibilityUITests: XCTestCase {
    private enum Timeouts {
        static let prompt: TimeInterval = 12
        static let mainUI: TimeInterval = 30
        static let dataVisible: TimeInterval = 20
    }

    private var storeURL: URL?

    override func tearDown() {
        storeURL = nil
        super.tearDown()
    }

    private func makeStoreURL() -> URL {
        let base = FileManager.default.temporaryDirectory
        return base.appendingPathComponent("OffshoreUITest-\(UUID().uuidString).sqlite")
    }

    @discardableResult
    private func launchApp(
        skipOnboarding: Bool,
        resetState: Bool,
        startTab: String? = nil,
        seed: String? = nil,
        extraEnv: [String: String] = [:]
    ) -> XCUIApplication {
        if storeURL == nil { storeURL = makeStoreURL() }

        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launchEnvironment["UITEST_SKIP_ONBOARDING"] = skipOnboarding ? "1" : "0"
        app.launchEnvironment["UITEST_RESET_STATE"] = resetState ? "1" : "0"
        app.launchEnvironment["UITEST_DISABLE_ANIMATIONS"] = "1"
        app.launchEnvironment["UITEST_STORE_PATH"] = storeURL!.path
        app.launchEnvironment["UITEST_RUN_ID"] = extraEnv["UITEST_RUN_ID"] ?? UUID().uuidString
        app.launchEnvironment["UITEST_LOCALE"] = extraEnv["UITEST_LOCALE"] ?? "en_US"
        app.launchEnvironment["UITEST_TIMEZONE"] = extraEnv["UITEST_TIMEZONE"] ?? "UTC"
        if let startTab {
            app.launchEnvironment["UITEST_START_TAB"] = startTab
        }
        if let seed {
            app.launchEnvironment["UITEST_SEED"] = seed
        }
        extraEnv.forEach { key, value in
            app.launchEnvironment[key] = value
        }
        app.launch()
        return app
    }

    private func tapButtonLabeled(_ label: String, in app: XCUIApplication, timeout: TimeInterval, file: StaticString = #file, line: UInt = #line) {
        let direct = app.buttons[label].firstMatch
        XCTAssertTrue(direct.waitForExistence(timeout: timeout), "Missing button: \(label)", file: file, line: line)
        direct.tap()
    }

    private func waitForMainUI(in app: XCUIApplication, file: StaticString = #file, line: UInt = #line) {
        let homeScreen = app.otherElements["home_screen"]
        if homeScreen.waitForExistence(timeout: Timeouts.mainUI) { return }
        let homeTab = app.descendants(matching: .any).matching(identifier: "tab_home").firstMatch
        XCTAssertTrue(homeTab.waitForExistence(timeout: Timeouts.mainUI), "Main UI did not appear", file: file, line: line)
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
        let anyMatch = app.descendants(matching: .any).matching(identifier: id).firstMatch
        XCTAssertTrue(anyMatch.waitForExistence(timeout: 6), "Tab not found: \(id)", file: file, line: line)
        anyMatch.tap()
    }

    // MARK: - Tests

    func testScenario1_useICloudThenUseICloudData_showsDataWithoutRelaunch_characterization() {
        let seededWorkspaceID = "99999999-8888-7777-6666-555555555555"
        let activeWorkspaceID = "00000000-1111-2222-3333-444444444444"

        let app = launchApp(
            skipOnboarding: false,
            resetState: true,
            startTab: "home",
            seed: "cloud_workspace_mismatch",
            extraEnv: [
                "UITEST_EXERCISE_ICLOUD_PROMPTS": "1",
                "UITEST_BYPASS_CLOUD_IMPORT_WAIT": "0",
                "UITEST_SEED_WORKSPACE_ID": seededWorkspaceID,
                "UITEST_ACTIVE_WORKSPACE_ID": activeWorkspaceID
            ]
        )

        tapButtonLabeled("Use iCloud", in: app, timeout: Timeouts.prompt)
        tapButtonLabeled("Use iCloud Data", in: app, timeout: Timeouts.prompt)

        waitForMainUI(in: app)

        tapTab("tab_budgets", in: app)
        let coreBudget = app.staticTexts["Core Budget"].firstMatch
        XCTAssertTrue(coreBudget.waitForExistence(timeout: Timeouts.dataVisible), "Expected existing iCloud data to be visible without relaunch")
    }

    func testScenario2_notNowThenOnboardThenEnableICloudLater() {
        let app = launchApp(
            skipOnboarding: false,
            resetState: true,
            startTab: "home",
            seed: nil,
            extraEnv: [
                "UITEST_EXERCISE_ICLOUD_PROMPTS": "1"
            ]
        )

        tapButtonLabeled("Not Now", in: app, timeout: Timeouts.prompt)

        let onboarding = app.otherElements["onboarding_screen"]
        XCTAssertTrue(onboarding.waitForExistence(timeout: Timeouts.prompt))

        tapButtonLabeled("Get Started", in: app, timeout: Timeouts.prompt)
        for _ in 0..<3 {
            tapButtonLabeled("Done", in: app, timeout: Timeouts.prompt)
        }

        waitForMainUI(in: app)

        tapTab("tab_settings", in: app)
        let iCloudNav = app.descendants(matching: .any).matching(identifier: "nav_settings_icloud").firstMatch
        XCTAssertTrue(iCloudNav.waitForExistence(timeout: Timeouts.prompt))
        iCloudNav.tap()

        let cloudToggle = app.switches["Enable iCloud Sync"].firstMatch
        XCTAssertTrue(cloudToggle.waitForExistence(timeout: Timeouts.prompt))
        cloudToggle.tap()

        // Basic sanity: widgets sync toggle should exist (and is disabled until cloudToggle is on).
        let widgetToggle = app.switches["Sync Home Widgets Across Devices"].firstMatch
        XCTAssertTrue(widgetToggle.waitForExistence(timeout: Timeouts.prompt))
    }

    func testScenario3_useICloudThenStartFresh_thenOnboard() {
        let app = launchApp(
            skipOnboarding: false,
            resetState: true,
            startTab: "home",
            seed: nil,
            extraEnv: [
                "UITEST_EXERCISE_ICLOUD_PROMPTS": "1"
            ]
        )

        tapButtonLabeled("Use iCloud", in: app, timeout: Timeouts.prompt)
        tapButtonLabeled("Start Fresh", in: app, timeout: Timeouts.prompt)

        let onboarding = app.otherElements["onboarding_screen"]
        XCTAssertTrue(onboarding.waitForExistence(timeout: Timeouts.prompt))

        tapButtonLabeled("Get Started", in: app, timeout: Timeouts.prompt)
        for _ in 0..<3 {
            tapButtonLabeled("Done", in: app, timeout: Timeouts.prompt)
        }

        waitForMainUI(in: app)
    }
}
