import SwiftUI

// Minimal replacement for legacy CategoryChipPill used by add/edit forms.
// Provides a simple rounded rectangle pill with configurable colors.
struct CategoryChipPill<Label: View>: View {
    let isSelected: Bool
    let glassTint: Color?
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
        self.glassTint = glassTint
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
            .foregroundStyle(textColor)
            .padding(.horizontal, 12)
            .frame(height: 33)
            .background(backgroundView)
            .overlay(overlayView)
            .clipShape(Capsule())
            .contentShape(RoundedRectangle(cornerRadius: 16))
    }

    private var textColor: Color {
        if #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *), glassTint != nil {
            return glassTextColor
        }
        return fallbackTextColor
    }

    @ViewBuilder
    private var backgroundView: some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        if #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *), let glassTint {
            shape
                .fill(glassTint)
                .glassEffect(.regular, in: .rect(cornerRadius: 16))
        } else {
            shape.fill(fallbackFill)
        }
    }

    @ViewBuilder
    private var overlayView: some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        if #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *), glassTint != nil {
            shape.stroke(Color.primary.opacity(0.12), lineWidth: 0.8)
        } else {
            shape.stroke(fallbackStrokeColor, lineWidth: fallbackStrokeLineWidth)
        }
    }
}
