import XCTest
import CoreGraphics
import Foundation

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

        // Choose host in priority order
        let table = app.tables.firstMatch
        let collection = app.collectionViews.firstMatch
        let scroll = app.scrollViews.firstMatch
        let host: XCUIElement
        if table.exists { host = table }
        else if collection.exists { host = collection }
        else if scroll.exists { host = scroll }
        else { host = app.windows.firstMatch }
        guard host.exists else { return 0 }

        // Give content a chance to settle and reveal tail content
        for _ in 0..<3 { host.swipeUp() }

        // Prefer a DEBUG-only anchor if present (first inside host, then global)
        let anchor = host.descendants(matching: .any).matching(NSPredicate(format: "identifier == %@", "BottomTailAnchor")).firstMatch
        if anchor.exists && anchor.frame.maxY < tabTop {
            return max(0, tabTop - anchor.frame.maxY)
        }
        let globalAnchor = app.descendants(matching: .any).matching(NSPredicate(format: "identifier == %@", "BottomTailAnchor")).firstMatch
        if globalAnchor.exists && globalAnchor.frame.maxY < tabTop {
            return max(0, tabTop - globalAnchor.frame.maxY)
        }

        // Otherwise restrict candidates to cells when possible to avoid picking
        // background/placeholder views.
        let candidates: [XCUIElement]
        if table.exists {
            candidates = table.cells.allElementsBoundByIndex.filter { $0.frame.maxY < tabTop }
        } else if collection.exists {
            candidates = collection.cells.allElementsBoundByIndex.filter { $0.frame.maxY < tabTop }
        } else {
            candidates = host.descendants(matching: .any).allElementsBoundByIndex
                .filter { $0.exists && $0.frame.height > 0 && $0.frame.maxY < tabTop }
        }
        guard let bottomMost = candidates.max(by: { $0.frame.maxY < $1.frame.maxY }) else { return 0 }
        return max(0, tabTop - bottomMost.frame.maxY)
    }

    // MARK: - Diagnostic (no assertions)
    /// Same as measureUnderbarGap, but also returns diagnostic info about which
    /// element was used and from which host it was chosen. Helpful to ensure we
    /// aren't accidentally measuring against a background/placeholder.
    @MainActor
    private func measureUnderbarGapWithInfo(in app: XCUIApplication) -> (gap: CGFloat, hostType: String, bottomDesc: String, bottomFrame: CGRect, candidatesCount: Int) {
        let tabBar = app.tabBars.firstMatch
        _ = tabBar.waitForExistence(timeout: 2)
        let tabTop = tabBar.frame.minY

        let tables = app.tables.firstMatch
        let collections = app.collectionViews.firstMatch
        let scrolls = app.scrollViews.firstMatch
        let host: XCUIElement
        let hostType: String
        if tables.exists { host = tables; hostType = "UITableView (List)" }
        else if collections.exists { host = collections; hostType = "UICollectionView" }
        else if scrolls.exists { host = scrolls; hostType = "UIScrollView" }
        else { host = app.windows.firstMatch; hostType = "Window" }

        for _ in 0..<3 { host.swipeUp() }

        // Prefer anchor when present (first inside host, then global)
        let anchor = host.descendants(matching: .any).matching(NSPredicate(format: "identifier == %@", "BottomTailAnchor")).firstMatch
        if anchor.exists && anchor.frame.maxY < tabTop {
            let gap = max(0, tabTop - anchor.frame.maxY)
            return (gap, hostType, anchor.debugDescription, anchor.frame, 1)
        }
        let globalAnchor = app.descendants(matching: .any).matching(NSPredicate(format: "identifier == %@", "BottomTailAnchor")).firstMatch
        if globalAnchor.exists && globalAnchor.frame.maxY < tabTop {
            let gap = max(0, tabTop - globalAnchor.frame.maxY)
            return (gap, "Global", globalAnchor.debugDescription, globalAnchor.frame, 1)
        }

        let candidates: [XCUIElement]
        if tables.exists {
            candidates = tables.cells.allElementsBoundByIndex.filter { $0.frame.maxY < tabTop }
        } else if collections.exists {
            candidates = collections.cells.allElementsBoundByIndex.filter { $0.frame.maxY < tabTop }
        } else {
            let all = host.descendants(matching: .any).allElementsBoundByIndex
            candidates = all.filter { $0.exists && $0.frame.height > 0 && $0.frame.maxY < tabTop }
        }
        guard let bottomMost = candidates.max(by: { $0.frame.maxY < $1.frame.maxY }) else {
            return (0, hostType, "<no bottom candidate>", .zero, candidates.count)
        }

        let gap = max(0, tabTop - bottomMost.frame.maxY)
        return (gap, hostType, bottomMost.debugDescription, bottomMost.frame, candidates.count)
    }

    @MainActor
    func testUnderbarGapDebug_HomeLegacy() throws {
        #if os(iOS)
        if ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 26 {
            throw XCTSkip("Skipping: OS26+")
        }
        let app = launchSkippingOnboarding()
        openTab(.home, in: app)
        let info = measureUnderbarGapWithInfo(in: app)
        XCTContext.runActivity(named: "Host=\(info.hostType) gap=\(info.gap) count=\(info.candidatesCount)") { _ in
            let meta = "Host: \(info.hostType)\nGap: \(info.gap)\nCandidates: \(info.candidatesCount)\nBottom frame: \(info.bottomFrame)\nBottom debug: \n\(info.bottomDesc)\n"
            print(meta)
            NSLog("%@", meta)
            let att = XCTAttachment(string: meta)
            att.name = "UnderbarGap_Debug_Home"
            att.lifetime = .keepAlways
            add(att)
        }
        // Always attach a screenshot for context
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "UnderbarGap_Debug_Home_Screenshot"
        shot.lifetime = .keepAlways
        add(shot)
        #else
        throw XCTSkip("iOS-only UI test")
        #endif
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
