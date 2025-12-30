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

    var body: some View {
        let dot = UBColorFromHex(hex) ?? .secondary
        let chipLabel = HStack(spacing: 8) {
            Circle().fill(dot).frame(width: 8, height: 8)
            Text(title).font(.subheadline.weight(.medium))
            Text(formatCurrency(amount))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isExceeded ? Color.red : Color.primary)
        }
        .padding(.horizontal, 12)
        .frame(height: 44)
        .background(.clear)

        if #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *) {
            Button(action: onTap) {
                chipLabel
                    .glassEffect(
                        .regular
                            .tint(isSelected ? dot.opacity(0.25) : .clear)
                            .interactive(true)
                    )
                    .frame(minHeight: 44, maxHeight: 44)
            }
            .buttonBorderShape(.capsule)
            .foregroundStyle(.primary)
            .allowsHitTesting(true)
            .disabled(false)
            .frame(minHeight: 44, maxHeight: 44)
            .clipShape(Capsule())
            .compositingGroup()
            .accessibilityAddTraits(isSelected ? .isSelected : [])
        } else {
            Button(action: onTap) {
                chipLabel
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .frame(minHeight: 44, maxHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(
                        isSelected
                        ? dot.opacity(0.20)
                        : Color(UIColor { traits in
                            traits.userInterfaceStyle == .dark ? UIColor(white: 0.22, alpha: 1) : UIColor(white: 0.9, alpha: 1)
                        })
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(isSelected ? dot.opacity(0.35) : .clear, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .frame(minHeight: 44, maxHeight: 44)
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
