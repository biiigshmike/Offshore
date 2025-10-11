import SwiftUI

// Minimal replacement for legacy CategoryChipPill used by add/edit forms.
// Provides a simple rounded rectangle pill with configurable colors.
struct CategoryChipPill<Label: View>: View {
    let isSelected: Bool
    let glassTextColor: Color
    let fallbackTextColor: Color
    let fallbackFill: Color
    let fallbackStrokeColor: Color
    let fallbackStrokeLineWidth: CGFloat
    let isInteractive: Bool
    @ViewBuilder var label: () -> Label

    init(
        isSelected: Bool = false,
        glassTint: Color? = nil,
        glassTextColor: Color = .primary,
        fallbackTextColor: Color = .primary,
        fallbackFill: Color = Color(UIColor.systemGray5),
        fallbackStrokeColor: Color = .clear,
        fallbackStrokeLineWidth: CGFloat = 0,
        isInteractive: Bool = false,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.isSelected = isSelected
        _ = glassTint
        self.glassTextColor = glassTextColor
        self.fallbackTextColor = fallbackTextColor
        self.fallbackFill = fallbackFill
        self.fallbackStrokeColor = fallbackStrokeColor
        self.fallbackStrokeLineWidth = fallbackStrokeLineWidth
        self.isInteractive = isInteractive
        self.label = label
    }

    var body: some View {
        label()
            .font(.footnote.weight(.semibold))
            .foregroundStyle(fallbackTextColor)
            .padding(.horizontal, 12)
            .frame(height: 33)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(fallbackFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(fallbackStrokeColor, lineWidth: fallbackStrokeLineWidth)
            )
            .contentShape(RoundedRectangle(cornerRadius: 16))
    }
}
