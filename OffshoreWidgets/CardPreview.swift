import SwiftUI

struct CardPreview: View {
    let cardName: String?
    let primaryHex: String?
    let secondaryHex: String?

    var body: some View {
        let primary = Color(hex: primaryHex) ?? Color.secondary.opacity(0.2)
        let secondary = Color(hex: secondaryHex) ?? primary.opacity(0.8)

        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(LinearGradient(colors: [primary, secondary], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .overlay(alignment: .bottomLeading) {
                if let cardName, !cardName.isEmpty {
                    Text(cardName)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .padding(6)
                }
            }
    }
}

extension Color {
    init?(hex: String?) {
        guard let hex else { return nil }
        let trimmed = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard trimmed.count == 6 || trimmed.count == 8 else { return nil }
        var int: UInt64 = 0
        guard Scanner(string: trimmed).scanHexInt64(&int) else { return nil }
        let a, r, g, b: UInt64
        if trimmed.count == 8 {
            a = (int >> 24) & 0xff
            r = (int >> 16) & 0xff
            g = (int >> 8) & 0xff
            b = int & 0xff
        } else {
            a = 255
            r = (int >> 16) & 0xff
            g = (int >> 8) & 0xff
            b = int & 0xff
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
