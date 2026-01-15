import SwiftUI

// MARK: - DesignSystemV2.HomeListRowStyle
extension DesignSystemV2 {
    /// Home-only list row chrome helper.
    ///
    /// Intentional scope: `HomeView.swift` and views defined in that same file.
    /// Do not use this outside Home without an explicit scope decision.
    struct HomeListRowStyle: ViewModifier {
        let insets: EdgeInsets

        func body(content: Content) -> some View {
            content
                .listRowInsets(insets)
                .listRowSeparator(.hidden)
                .listRowBackground(Colors.clear)
                .ub_preOS26ListRowBackground(Colors.clear)
        }
    }
}

extension View {
    func homeListRowStyle(insets: EdgeInsets) -> some View {
        modifier(DesignSystemV2.HomeListRowStyle(insets: insets))
    }
}

