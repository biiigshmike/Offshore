import SwiftUI

// MARK: - GuidedTourOverlay
struct GuidedTourOverlay: View {
    @Environment(\.platformCapabilities) private var platformCapabilities

    let title: String
    let message: String
    let bullets: [String]
    let onClose: () -> Void

    init(title: String, message: String, bullets: [String] = [], onClose: @escaping () -> Void) {
        self.title = title
        self.message = message
        self.bullets = bullets
        self.onClose = onClose
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .accessibilityHidden(true)
                .onTapGesture(perform: onClose)

            overlayCard
                .padding(.horizontal, 24)
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityLabel(Text(title))
        .accessibilityValue(Text(message))
        .accessibilityAction(.escape, onClose)
    }

    private var overlayCard: some View {
        Group {
            if platformCapabilities.supportsOS26Translucency {
                glassCard
            } else {
                legacyCard
            }
        }
        .frame(maxWidth: 420)
    }

    private var glassCard: some View {
        GlassEffectContainer(spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                header
                Text(message)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                bulletList
            }
            .padding(28)
            .glassEffect(.regular.tint(.clear).interactive(true), in: .rect(cornerRadius: 28))
        }
    }

    private var legacyCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            Text(message)
                .font(.body)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            bulletList
        }
        .padding(28)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.25), radius: 24, x: 0, y: 8)
    }

    @ViewBuilder
    private var bulletList: some View {
        if !bullets.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(bullets.enumerated()), id: \.offset) { item in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.tint)
                            .accessibilityHidden(true)
                        Text(item.element)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .transition(.opacity)
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3.weight(.semibold))
                Text("Let’s take a quick tour.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 12)
            closeButton
        }
        .accessibilityElement(children: .combine)
    }

    private var closeButton: some View {
        Group {
            if platformCapabilities.supportsOS26Translucency {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(width: 44, height: 44)
                        .glassEffect(.regular.tint(.clear).interactive(true), in: .capsule)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close guided tour overlay")
                .keyboardShortcut(.cancelAction)
            } else {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.25))
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close guided tour overlay")
                .keyboardShortcut(.cancelAction)
            }
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Previews
#Preview("OS26") {
    GuidedTourOverlay(
        title: "Welcome to Home",
        message: "Keep track of your current budget period, planned spending, and variable purchases in one view.",
        bullets: [
            "Use the toolbar to jump between periods and add new expenses.",
            "Swipe the segmented control to switch between planned and variable spend.",
        ],
        onClose: {}
    )
    .environment(\.platformCapabilities, PlatformCapabilities(supportsOS26Translucency: true, supportsAdaptiveKeypad: true))
}

#Preview("Legacy") {
    GuidedTourOverlay(
        title: "Welcome to Home",
        message: "Keep track of your current budget period, planned spending, and variable purchases in one view.",
        bullets: [
            "Use the toolbar to jump between periods and add new expenses.",
            "Swipe the segmented control to switch between planned and variable spend.",
        ],
        onClose: {}
    )
    .environment(\.platformCapabilities, PlatformCapabilities(supportsOS26Translucency: false, supportsAdaptiveKeypad: false))
}
