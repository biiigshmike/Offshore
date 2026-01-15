import SwiftUI

// MARK: - DesignSystemV2.ChipLegacySurface
extension DesignSystemV2 {
    struct ChipLegacySurface: ViewModifier {
        let shape: RoundedRectangle
        let fill: Color
        let stroke: Color
        let lineWidth: CGFloat

        init(shape: RoundedRectangle, fill: Color, stroke: Color, lineWidth: CGFloat = 1) {
            self.shape = shape
            self.fill = fill
            self.stroke = stroke
            self.lineWidth = lineWidth
        }

        func body(content: Content) -> some View {
            content
                .background(shape.fill(fill))
                .overlay(shape.stroke(stroke, lineWidth: lineWidth))
                .contentShape(shape)
        }
    }
}
