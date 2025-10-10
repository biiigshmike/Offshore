#if os(iOS) && !targetEnvironment(macCatalyst)
import SwiftUI
import UIKit
import Testing
@testable import Offshore

@MainActor
struct BudgetListInsetTunerTests {

    @Test
    func legacyListTailMatchesDesignSpacing() {
        guard #unavailable(iOS 26.0) else { return }

        let window = TestWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 640))
        window.customSafeAreaInsets = .zero

        let controller = UIHostingController(rootView: LegacyBudgetListSample())
        let _ = controller.view
        controller.view.backgroundColor = .clear

        window.rootViewController = controller
        window.makeKeyAndVisible()
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }

        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
        controller.view.layoutIfNeeded()

        guard let scrollView = controller.view.firstScrollView() else {
            Issue.record("Expected embedded scroll view")
            return
        }

        #expect(abs(scrollView.contentInset.bottom - 0) < 0.5)

        guard let anchor = controller.view.findView(accessibilityIdentifier: "TestBottomTailAnchor") else {
            Issue.record("Missing bottom tail anchor")
            return
        }

        let anchorFrame = anchor.convert(anchor.bounds, to: controller.view)
        let bottomGap = controller.view.bounds.maxY - anchorFrame.minY
        #expect(abs(bottomGap - DesignSystem.Spacing.l) < 0.5)
    }
}

private final class TestWindow: UIWindow {
    var customSafeAreaInsets: UIEdgeInsets = .zero
    override var safeAreaInsets: UIEdgeInsets { customSafeAreaInsets }
}

private struct LegacyBudgetListSample: View {
    var body: some View {
        List {
            Text("One")
            Text("Two")
        }
        .overlay(alignment: .topLeading) {
            UBBudgetListInsetTuner()
                .frame(width: 0, height: 0)
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear
                .frame(height: DesignSystem.Spacing.l)
                .overlay(alignment: .topLeading) {
                    Color.clear
                        .frame(width: 1, height: 1)
                        .accessibilityIdentifier("TestBottomTailAnchor")
                }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}

private extension UIView {
    func findView(accessibilityIdentifier identifier: String) -> UIView? {
        if accessibilityIdentifier == identifier { return self }
        for subview in subviews {
            if let match = subview.findView(accessibilityIdentifier: identifier) {
                return match
            }
        }
        return nil
    }

    func firstScrollView() -> UIScrollView? {
        if let scroll = self as? UIScrollView {
            return scroll
        }
        for subview in subviews {
            if let match = subview.firstScrollView() {
                return match
            }
        }
        return nil
    }
}
#endif
