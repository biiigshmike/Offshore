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

            // MARK: Safe-area-only bottom inset policy
            let windowSafeBottom = max(scroll.window?.safeAreaInsets.bottom ?? 0, 0)
            let desiredBottom = windowSafeBottom

            let needsContentInsetUpdate = abs(scroll.contentInset.bottom - desiredBottom) > 0.5
            let needsIndicatorReset = scroll.verticalScrollIndicatorInsets.bottom != 0

            guard needsContentInsetUpdate || needsIndicatorReset else { return }

            if needsContentInsetUpdate {
                var inset = scroll.contentInset
                inset.bottom = desiredBottom
                scroll.contentInset = inset
            }

            // Keep indicators flush; we don't need extra bottom room for them.
            if needsIndicatorReset {
                scroll.verticalScrollIndicatorInsets.bottom = 0
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
