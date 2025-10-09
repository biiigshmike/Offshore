import SwiftUI
import UIKit

#if os(iOS)
/// Neutralizes UIKit's automatic bottom lift for scroll containers (UIScrollView/UITableView)
/// so content can extend behind the tab bar on legacy OS versions. Top inset handling
/// is preserved by leaving `contentInsetAdjustmentBehavior` untouched; we only zero
/// the bottom content/indicator insets and disable automatic indicator inset tweaks.
struct UBUnderbarScrollInsetsNeutralizer: UIViewRepresentable {
    func makeUIView(context: Context) -> UBUnderbarNeutralizerView {
        UBUnderbarNeutralizerView()
    }

    func updateUIView(_ uiView: UBUnderbarNeutralizerView, context: Context) {
        uiView.applyIfNeeded()
    }
}

final class UBUnderbarNeutralizerView: UIView {
    override func didMoveToWindow() {
        super.didMoveToWindow()
        applyIfNeeded()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        applyIfNeeded()
    }

    func applyIfNeeded() {
        guard let vc = nearestViewController(startingFrom: self) else { return }
        neutralizeBottomInsets(in: vc.view)
    }

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

    private func nearestViewController(startingFrom view: UIView) -> UIViewController? {
        var responder: UIResponder? = view
        while let r = responder {
            if let vc = r as? UIViewController { return vc }
            responder = r.next
        }
        return nil
    }
}

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

extension View {
    func ub_legacyUnderbarScroll() -> some View {
        modifier(UBLegacyUnderbarScrollAllowance())
    }
}
#endif

