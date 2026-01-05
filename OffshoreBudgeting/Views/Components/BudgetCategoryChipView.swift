#if canImport(UIKit)
import UIKit
#endif
import SwiftUI

struct BudgetCategoryChipView: View {
    let title: String
    let amount: Double
    let hex: String?
    let isSelected: Bool
    let isExceeded: Bool
    let onTap: () -> Void
    @ScaledMetric(relativeTo: .subheadline) private var dotSize: CGFloat = 8
    @ScaledMetric(relativeTo: .body) private var minHeight: CGFloat = 44

    var body: some View {
        let dot = UBColorFromHex(hex) ?? .secondary
        let chipLabel = HStack(spacing: 8) {
            Circle().fill(dot).frame(width: dotSize, height: dotSize)
            Text(title).font(.subheadline.weight(.medium))
            Text(formatCurrency(amount))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isExceeded ? Color.red : Color.primary)
        }
        .padding(.horizontal, 12)
        .frame(minHeight: minHeight)
        .background(.clear)

        if #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *) {
            Button(action: onTap) {
                chipLabel
                    .glassEffect(
                        .regular
                            .tint(isSelected ? dot.opacity(0.25) : .clear)
                            .interactive(true)
                    )
                    .frame(minHeight: minHeight)
            }
            .buttonBorderShape(.capsule)
            .foregroundStyle(.primary)
            .allowsHitTesting(true)
            .disabled(false)
            .frame(minHeight: minHeight)
            .clipShape(Capsule())
            .compositingGroup()
            .accessibilityAddTraits(isSelected ? .isSelected : [])
        } else {
            Button(action: onTap) {
                chipLabel
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .frame(minHeight: minHeight)
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(isSelected ? dot.opacity(0.35) : Color.primary.opacity(0.15), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .frame(minHeight: minHeight)
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        if #available(iOS 15.0, macCatalyst 15.0, *) {
            let currencyCode: String
            if #available(iOS 16.0, macCatalyst 16.0, *) {
                currencyCode = Locale.current.currency?.identifier ?? "USD"
            } else {
                currencyCode = Locale.current.currencyCode ?? "USD"
            }
            return amount.formatted(.currency(code: currencyCode))
        } else {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = Locale.current.currencyCode ?? "USD"
            return formatter.string(from: amount as NSNumber) ?? String(format: "%.2f", amount)
        }
    }
}
