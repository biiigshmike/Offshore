import SwiftUI

// Minimal placeholder to satisfy legacy build references.
// Old calendar nav styling was removed; this no-op style preserves
// compatibility if the Xcode project still lists this file in a build phase.
struct CalendarNavigationButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

