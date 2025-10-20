import SwiftUI

/// Full-screen setup screen shown while preparing Core Data and/or syncing
/// from iCloud before presenting the main tabs. Keeps a stable surface with
/// a small, dynamic subtitle so there’s no flicker between states.
struct WorkspaceSetupView: View {
    let isSyncing: Bool

    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.platformCapabilities) private var capabilities

    var body: some View {
        ZStack {
            // Background: use liquid glass on modern OS, themed color legacy
            if #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *) {
                GeometryReader { proxy in
                    let corner = max(16, min(proxy.size.width, proxy.size.height) * 0.04)
                    // A full-screen rounded-rectangle glass surface (not capsule),
                    // scaled to the device and clipped to safe area.
                    Rectangle()
                        .fill(Color.clear)
                        .glassEffect(.regular.tint(.none), in: RoundedRectangle(cornerRadius: corner, style: .continuous))
                        .opacity(0.92)
                        .ignoresSafeArea()
                }
            } else {
                themeManager.selectedTheme.background
                    .overlay(Color.black.opacity(capabilities.supportsOS26Translucency ? 0.04 : 0.06))
                    .ignoresSafeArea()
            }

            VStack(spacing: 14) {
                // Title
                Text("Setting up your budget workspace…")
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)

                // Progress
                ProgressView()

                // Subtitle
                Text(subtitle)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
            .frame(maxWidth: 560)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Setting up your budget workspace")
    }

    private var subtitle: String {
        if isSyncing { return "Syncing your data… This can take a moment." }
        return "Preparing…"
    }
}
