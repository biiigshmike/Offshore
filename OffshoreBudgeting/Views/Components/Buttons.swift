import SwiftUI

// MARK: - Buttons
/// Tiny, reusable button builders that follow the "Apple Way":
/// - Prefer system styles (`.glass`) on OS 26+
/// - Provide simple, readable fallbacks on earlier OS versions
/// - Keep call sites compact and intention‑revealing
enum Buttons {

    // MARK: Primary CTA
    /// Builds a primary call‑to‑action button.
    /// - Parameters:
    ///   - title: Visible label text.
    ///   - systemImage: Optional SF Symbol name shown before the title.
    ///   - fillHorizontally: When true, expands to full width.
    ///   - action: Invoked on tap.
    /// - Returns: A view rendering the button with glass on OS 26+ and a plain fallback otherwise.
    static func primary(
        _ title: String,
        systemImage: String? = nil,
        fillHorizontally: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Group {
            if #available(iOS 26.0, macOS 26.0, macCatalyst 26.0, *) {
                Button(action: action) {
                    Label(title, systemImage: systemImage ?? "")
                        .labelStyle(.titleAndIcon)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .frame(maxWidth: fillHorizontally ? .infinity : nil)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .glassEffect(.regular.tint(.blue.opacity(0.0125)).interactive())
                }
                .buttonStyle(.plain)
                .buttonBorderShape(.capsule)
            } else {
                Button(action: action) {
                    HStack(spacing: 8) {
                        if let name = systemImage { Image(systemName: name) }
                        Text(title)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                    }
                    .frame(maxWidth: fillHorizontally ? .infinity : nil)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                }
                .buttonStyle(.plain)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.secondary.opacity(0.12))
                )
            }
        }
    }

    // MARK: Toolbar Icon
    /// Builds a tappable tool‑bar icon.
    /// - Parameters:
    ///   - systemImage: SF Symbol name.
    ///   - action: Invoked on tap.
    /// - Returns: A view rendering the toolbar icon with glass on OS 26+ and a plain fallback otherwise.
    static func toolbarIcon(
        _ systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        // Toolbar icons should be visually "clear" (no grey/tinted backgrounds)
        // even on OS 26, per design feedback.
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 33, height: 33)
        }
        .buttonStyle(.plain)
    }

    // MARK: Toolbar Icon (glass preferred)
    /// Glass on OS 26+, plain elsewhere. Useful for contexts where
    /// a translucent affordance is desired (e.g., IncomeView).
    static func toolbarIconGlassPreferred(
        _ systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Group {
            if #available(iOS 26.0, macOS 26.0, macCatalyst 26.0, *) {
                Button(action: action) {
                    Image(systemName: systemImage)
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 33, height: 33)
                        .glassEffect(.regular.tint(.none).interactive(true))
                }
                .buttonStyle(.plain)
                .buttonBorderShape(.circle)
                .tint(.accentColor)
            } else {
                Button(action: action) {
                    Image(systemName: systemImage)
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 33, height: 33)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
