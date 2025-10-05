import SwiftUI

/// Reusable list row background that cooperates with Liquid Glass on OS 26,
/// and falls back to a rounded, grouped fill with a separator on legacy OSes.
struct UBFormListRowBackground: View {
    let theme: AppTheme
    @Environment(\.platformCapabilities) private var capabilities

    init(theme: AppTheme) { self.theme = theme }

    var body: some View {
        Group {
            if capabilities.supportsOS26Translucency {
                // Let system glass show through on modern OS
                Color.clear
            } else {
                // Opaque grouped row for legacy OSes
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.separator, lineWidth: 1)
                    )
            }
        }
    }
}
