import SwiftUI
import UIKit

/// Classic-only List tuner that neutralizes automatic bottom lifts on the
/// underlying scroll container used by SwiftUI `List` (UITableView on older
/// systems, UICollectionView on newer), without disturbing top inset behavior.
/// This keeps content close to the tab bar while avoiding extra bottom padding.
struct UBBudgetListInsetTuner: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView { UBBudgetListInsetNeutralizerView() }

    func updateUIView(_ uiView: UIView, context: Context) {
        (uiView as? UBBudgetListInsetNeutralizerView)?.applyIfNeeded()
    }
}

final class UBBudgetListInsetNeutralizerView: UIView {
    override func didMoveToWindow() {
        super.didMoveToWindow()
        applyIfNeeded()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        applyIfNeeded()
    }

    func applyIfNeeded() {
        guard let scroll = findEnclosingScrollView(startingFrom: self) else { return }
        // Classic only; defer to system behavior on OS26+
        if #available(iOS 26.0, *) {
            return
        } else {
            if #available(iOS 15.0, *) {
                scroll.automaticallyAdjustsScrollIndicatorInsets = false
            }

            // Match UIKit's safe-area derived inset so rows rest just above the tab bar.
            let desiredBottom = scroll.safeAreaInsets.bottom

            if abs(scroll.contentInset.bottom - desiredBottom) > 0.5 {
                var inset = scroll.contentInset
                inset.bottom = desiredBottom
                scroll.contentInset = inset
            }

            // Keep indicators flush; we don't need extra bottom room for them.
            if abs(scroll.verticalScrollIndicatorInsets.bottom - desiredBottom) > 0.5 {
                scroll.verticalScrollIndicatorInsets.bottom = desiredBottom
            }
        }
    }

    private func findEnclosingScrollView(startingFrom view: UIView) -> UIScrollView? {
        var current: UIView? = view
        while let v = current?.superview {
            if let sv = v as? UIScrollView { return sv }
            current = v
        }
        return nil
    }
}
