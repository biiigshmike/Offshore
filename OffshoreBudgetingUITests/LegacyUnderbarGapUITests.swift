import XCTest
import CoreGraphics

/// Detects large, persistent gaps above the tab bar that indicate a bottom overlay/lift
/// is obscuring content on legacy iOS. The test intentionally runs only on iOS
/// environments where OS26 Liquid Glass is unavailable.
final class LegacyUnderbarGapUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Root Tab DSL

    private enum RootTab: String, CaseIterable {
        case home = "Home"
        case income = "Income"
        case cards = "Cards"
        case presets = "Presets"
        case settings = "Settings"
    }

    @MainActor
    private func openTab(_ tab: RootTab, in app: XCUIApplication) {
        let label = tab.rawValue
        let tabBarButton = app.tabBars.buttons[label]
        if tabBarButton.waitForExistence(timeout: 3) {
            tabBarButton.tap()
            return
        }

        // Fallback: a plain button labeled with the tab title
        let predicate = NSPredicate(format: "label == %@", label)
        let fallback = app.buttons.matching(predicate).firstMatch
        if fallback.waitForExistence(timeout: 2) { fallback.tap() }
    }

    // MARK: - Measurement

    /// Returns the visual gap between the bottom-most content element inside the primary
    /// scroll host and the top edge of the tab bar. Values much larger than ~16pt suggest
    /// an overlay/lift is consuming space above the tab bar.
    @MainActor
    private func measureUnderbarGap(in app: XCUIApplication) -> CGFloat {
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 2) else { return 0 }
        let tabTop = tabBar.frame.minY

        // Prefer specific scroll hosts in priority order
        let containers: [XCUIElement] = [
            app.tables.firstMatch,
            app.collectionViews.firstMatch,
            app.scrollViews.firstMatch
        ].filter { $0.exists }

        let host = containers.first ?? app.windows.firstMatch
        guard host.exists else { return 0 }

        // Give content a chance to settle and to reveal tail content
        if host.exists {
            for _ in 0..<3 { host.swipeUp() }
        }

        let candidates = host.descendants(matching: .any).allElementsBoundByIndex
            .filter { $0.exists && $0.frame.height > 0 && $0.frame.maxY < tabTop }

        guard let bottomMost = candidates.max(by: { $0.frame.maxY < $1.frame.maxY }) else { return 0 }
        let gap = max(0, tabTop - bottomMost.frame.maxY)
        return gap
    }

    // MARK: - Launch

    @MainActor
    private func launchSkippingOnboarding() -> XCUIApplication {
        let app = XCUIApplication()
        if !app.launchArguments.contains("-didCompleteOnboarding") {
            app.launchArguments.append(contentsOf: ["-didCompleteOnboarding", "YES"])
        }
        app.launch()
        return app
    }

    // MARK: - Test

    /// Runs only on legacy iOS where OS26 Liquid Glass is unavailable. Measures the
    /// gap above the tab bar on each root tab and asserts it remains small.
    @MainActor
    func testUnderbarGapIsSmallOnLegacy() throws {
        #if os(iOS)
        // Skip on OS26+ devices; the behavior is expected to differ there.
        if ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 26 {
            throw XCTSkip("Skipping: OS26+")
        }

        let app = launchSkippingOnboarding()

        // Wait for tabs to appear
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 5))

        let allowedGap: CGFloat = 16 // pts

        for tab in RootTab.allCases {
            openTab(tab, in: app)
            let gap = measureUnderbarGap(in: app)

            XCTContext.runActivity(named: "Gap for \(tab.rawValue): \(gap)") { _ in }
            if gap > allowedGap {
                let attachment = XCTAttachment(screenshot: app.screenshot())
                attachment.name = "UnderbarGap_\(tab.rawValue)_\(gap)"
                attachment.lifetime = .keepAlways
                add(attachment)
            }
            XCTAssertLessThanOrEqual(gap, allowedGap, "Excessive gap above tab bar on \(tab.rawValue)")
        }
        #else
        throw XCTSkip("iOS-only UI test")
        #endif
    }
}
