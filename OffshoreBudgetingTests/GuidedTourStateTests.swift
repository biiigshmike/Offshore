import XCTest
#if canImport(Offshore)
@testable import Offshore
#elseif canImport(OffshoreBudgeting)
@testable import OffshoreBudgeting
#elseif canImport(SoFar)
@testable import SoFar
#else
#error("App module not found. Ensure the test target depends on the app target and update the conditional import.")
#endif

@MainActor
final class GuidedTourStateTests: XCTestCase {
    private func makeState() -> GuidedTourState {
        let suiteName = "GuidedTourTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return GuidedTourState(defaults: defaults, notificationCenter: NotificationCenter())
    }

    func testDefaultsRequireOverlayAndHints() {
        let state = makeState()
        for screen in GuidedTourScreen.allCases {
            XCTAssertTrue(state.needsOverlay(for: screen), "Overlay should be needed by default for \(screen)")
            XCTAssertTrue(state.needsHints(for: screen), "Hints should be needed by default for \(screen)")
        }
    }

    func testMarkingOverlayAndHintsPersists() {
        let state = makeState()
        state.markOverlaySeen(for: .home)
        state.markHintsDismissed(for: .home)

        XCTAssertFalse(state.needsOverlay(for: .home))
        XCTAssertFalse(state.needsHints(for: .home))
    }

    func testResetAllClearsFlags() {
        let state = makeState()
        state.markOverlaySeen(for: .cards)
        state.markHintsDismissed(for: .cards)

        state.resetAll()

        XCTAssertTrue(state.needsOverlay(for: .cards))
        XCTAssertTrue(state.needsHints(for: .cards))
    }

    func testForceOverlaysOnceOverridesSeenState() {
        let state = makeState()
        state.markOverlaySeen(for: .income)
        XCTAssertFalse(state.needsOverlay(for: .income))

        state.forceAllOverlaysOnce()
        XCTAssertTrue(state.needsOverlay(for: .income))

        state.markOverlaySeen(for: .income)
        XCTAssertFalse(state.needsOverlay(for: .income))
    }
}
