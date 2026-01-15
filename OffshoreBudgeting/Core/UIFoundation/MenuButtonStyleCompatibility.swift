import SwiftUI

// MARK: - Menu Button Style
extension View {
    @ViewBuilder
    // PLATFORM: KEEP
    func ub_menuButtonStyle() -> some View {
        if #available(iOS 16.0, macCatalyst 16.0, *) {
            self
                .buttonStyle(.plain)
                .buttonBorderShape(.capsule)
        } else {
            self
                .buttonStyle(.plain)
        }
    }
}
