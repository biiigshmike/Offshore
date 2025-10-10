import SwiftUI
import UIKit

#if os(iOS)
// MARK: - Overview (iOS)
/// Neutralizes UIKit's automatic bottom lift for scroll containers (UIScrollView/UITableView)
/// so content can extend behind the tab bar on legacy OS versions. Top inset handling
/// is preserved by leaving `contentInsetAdjustmentBehavior` untouched; we only zero
/// the bottom content/indicator insets and disable automatic indicator inset tweaks.
/// Supersedes the legacy ``UBScrollViewInsetAdjustmentDisabler`` helper so there's a
/// single traversal path for scroll inset neutralization.
struct UBUnderbarScrollInsetsNeutralizer: UIViewRepresentable {
    /// Creates a host view that can traverse the view tree to find scroll views.
    func makeUIView(context: Context) -> UBUnderbarNeutralizerView {
        UBUnderbarNeutralizerView()
    }

    /// Re-applies neutralization whenever SwiftUI updates the representable.
    func updateUIView(_ uiView: UBUnderbarNeutralizerView, context: Context) {
        uiView.applyIfNeeded()
    }
}

// MARK: - Neutralizer View (UIKit)
final class UBUnderbarNeutralizerView: UIView {
    override func didMoveToWindow() {
        super.didMoveToWindow()
        applyIfNeeded()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        applyIfNeeded()
    }

    /// Finds the nearest owning view controller and walks its view hierarchy to
    /// neutralize bottom insets on any discovered `UIScrollView`/`UITableView`.
    func applyIfNeeded() {
        guard let vc = nearestViewController(startingFrom: self) else { return }
        neutralizeBottomInsets(in: vc.view)
    }

    /// Depth-first traversal of `rootView` that zeroes bottom content/indicator
    /// insets and disables automatic indicator inset adjustments on iOS 15+.
    private func neutralizeBottomInsets(in rootView: UIView) {
        var stack: [UIView] = [rootView]
        while let view = stack.popLast() {
            if let scroll = view as? UIScrollView {
                if #available(iOS 15.0, *) {
                    scroll.automaticallyAdjustsScrollIndicatorInsets = false
                }
                if scroll.contentInset.bottom != 0 { scroll.contentInset.bottom = 0 }
                if scroll.verticalScrollIndicatorInsets.bottom != 0 {
                    scroll.verticalScrollIndicatorInsets.bottom = 0
                }
            }
            stack.append(contentsOf: view.subviews)
        }
    }

    /// Walks the responder chain to find the nearest `UIViewController` owner.
    private func nearestViewController(startingFrom view: UIView) -> UIViewController? {
        var responder: UIResponder? = view
        while let r = responder {
            if let vc = r as? UIViewController { return vc }
            responder = r.next
        }
        return nil
    }
}

// MARK: - Legacy Modifier
/// SwiftUI wrapper for the neutralizer; only active on legacy OS where OS26
/// Liquid Glass behavior isn't available.
struct UBLegacyUnderbarScrollAllowance: ViewModifier {
    @Environment(\.platformCapabilities) private var capabilities

    func body(content: Content) -> some View {
        if capabilities.supportsOS26Translucency {
            content
        } else {
            content.overlay(alignment: .topLeading) {
                UBUnderbarScrollInsetsNeutralizer()
                    .frame(width: 0, height: 0)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
    }
}

// MARK: - View Extension
extension View {
    /// Enables legacy under‑tab scrolling behavior by neutralizing bottom insets
    /// so content may extend behind the tab bar. No‑op on OS 26.
    func ub_legacyUnderbarScroll() -> some View {
        modifier(UBLegacyUnderbarScrollAllowance())
    }
}
#endif
