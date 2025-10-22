import SwiftUI

// MARK: - GuidedHintBubble
struct GuidedHintBubble: View {
    enum ArrowDirection {
        case up
        case down
        case leading
        case trailing
    }

    @Environment(\.platformCapabilities) private var platformCapabilities

    let icon: String
    let text: String
    let arrowDirection: ArrowDirection
    let onDismiss: () -> Void

    init(icon: String, text: String, arrowDirection: ArrowDirection, onDismiss: @escaping () -> Void) {
        self.icon = icon
        self.text = text
        self.arrowDirection = arrowDirection
        self.onDismiss = onDismiss
    }

    var body: some View {
        Group {
            switch arrowDirection {
            case .up:
                VStack(spacing: 0) {
                    arrowView.rotationEffect(.degrees(180))
                    bubbleSurface
                }
            case .down:
                VStack(spacing: 0) {
                    bubbleSurface
                    arrowView
                }
            case .leading:
                HStack(spacing: 0) {
                    arrowView.rotationEffect(.degrees(90))
                    bubbleSurface
                }
            case .trailing:
                HStack(spacing: 0) {
                    bubbleSurface
                    arrowView.rotationEffect(.degrees(-90))
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(text))
        .accessibilityHint(Text("Dismiss to continue"))
    }

    private var bubbleSurface: some View {
        Group {
            if platformCapabilities.supportsOS26Translucency {
                GlassEffectContainer(spacing: 0) {
                    bubbleContent
                        .padding(16)
                        .glassEffect(.regular.tint(.clear).interactive(true), in: .rect(cornerRadius: 18))
                }
            } else {
                bubbleContent
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white.opacity(0.92))
                            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                    )
            }
        }
    }

    private var bubbleContent: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .frame(width: 28, height: 28)
                .foregroundStyle(.tint)
                .accessibilityHidden(true)

            Text(text)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(.primary)

            Spacer(minLength: 8)

            closeButton
        }
        .frame(maxWidth: 260, alignment: .leading)
    }

    private var closeButton: some View {
        Group {
            if platformCapabilities.supportsOS26Translucency {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(width: 32, height: 32)
                        .glassEffect(.regular.tint(.clear).interactive(true), in: .capsule)
                }
                .buttonStyle(.plain)
            } else {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(width: 28, height: 28)
                        .background(
                            Circle().fill(Color.black.opacity(0.12))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .accessibilityLabel("Dismiss hint")
        .keyboardShortcut(.cancelAction)
    }

    private var arrowView: some View {
        Triangle()
            .fill(arrowFillColor)
            .frame(width: 18, height: 10)
            .allowsHitTesting(false)
    }

    private var arrowFillColor: Color {
        platformCapabilities.supportsOS26Translucency ? Color.white.opacity(0.45) : Color.white.opacity(0.9)
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Preference Key
struct GuidedHintAnchorPreferenceKey: PreferenceKey {
    static var defaultValue: [String: Anchor<CGRect>] = [:]

    static func reduce(value: inout [String: Anchor<CGRect>], nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

extension View {
    func guidedHintAnchor(_ id: String) -> some View {
        anchorPreference(key: GuidedHintAnchorPreferenceKey.self, value: .bounds) { anchor in
            [id: anchor]
        }
    }

    func guidedHintOverlay<Content: View>(@ViewBuilder content: @escaping (GeometryProxy, [String: Anchor<CGRect>]) -> Content) -> some View {
        overlayPreferenceValue(GuidedHintAnchorPreferenceKey.self) { anchors in
            GeometryReader { proxy in
                content(proxy, anchors)
            }
        }
    }
}

extension GeometryProxy {
    func frame(forHint id: String, anchors: [String: Anchor<CGRect>]) -> CGRect? {
        guard let anchor = anchors[id] else { return nil }
        return self[anchor]
    }
}

// MARK: - Previews
#Preview("OS26 Hint") {
    ZStack(alignment: .topTrailing) {
        Color.blue.opacity(0.1)
        GuidedHintBubble(
            icon: "sparkles",
            text: "Use the calendar to jump between budget periods.",
            arrowDirection: .down,
            onDismiss: {}
        )
        .padding()
    }
    .frame(width: 340, height: 220)
    .environment(\.platformCapabilities, PlatformCapabilities(supportsOS26Translucency: true, supportsAdaptiveKeypad: true))
}

#Preview("Legacy Hint") {
    ZStack(alignment: .topTrailing) {
        Color.green.opacity(0.1)
        GuidedHintBubble(
            icon: "sparkles",
            text: "Use the calendar to jump between budget periods.",
            arrowDirection: .down,
            onDismiss: {}
        )
        .padding()
    }
    .frame(width: 340, height: 220)
    .environment(\.platformCapabilities, PlatformCapabilities(supportsOS26Translucency: false, supportsAdaptiveKeypad: false))
}
