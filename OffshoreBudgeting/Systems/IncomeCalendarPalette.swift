//
//  IncomeCalendarPalette.swift
//  SoFar
//
//  Shared calendar components for MijickCalendarView.
//  Provides custom month and day views for the shared calendar presentation.
//

import SwiftUI
import MijickCalendarView

// MARK: - Month title (e.g., "August 2025")
struct UBMonthLabel: MonthLabel {
    // Required attribute (from MonthLabel)
    let month: Date

    @Environment(\.colorScheme) private var scheme
    @Environment(\.responsiveLayoutContext) private var layoutContext
    @ScaledMetric(relativeTo: .headline) private var monthLabelScale: CGFloat = 1

    func createContent() -> AnyView {
        let base = scheme == .dark ? Color.white : Color.black
        let fontSize = resolvedBaseFontSize(in: layoutContext) * monthLabelScale
        return AnyView(
            Text(getString(format: "MMMM y"))
                .font(.system(size: fontSize, weight: .semibold))
                .foregroundColor(base)
        )
    }

    private func resolvedBaseFontSize(in context: ResponsiveLayoutContext) -> CGFloat {
        let height = context.containerSize.height
        if height > 0, height < 500 { return 14 }
        if height > 0, height < 700 { return 16 }
        return 18
    }
}

// MARK: - Day cell with income summaries
/// Displays the day number plus optional planned/actual income amounts.
struct UBDayView: DayView {
    // Required attributes (from DayView)
    let date: Date
    let isCurrentMonth: Bool
    var selectedDate: Binding<Date?>?
    var selectedRange: Binding<MDateRange?>?
    let summary: (planned: Double, actual: Double)?
    /// External date used to force selection updates when navigation buttons are tapped.
    let selectedOverride: Date?
    /// Scale applied to typography and selection size for compact layouts.
    let scale: CGFloat

    @Environment(\.colorScheme) private var scheme
    @ScaledMetric(relativeTo: .caption) private var daySpacingBase: CGFloat = 2
    @ScaledMetric(relativeTo: .caption) private var daySpacingMin: CGFloat = 1
    @ScaledMetric(relativeTo: .caption) private var incomeSpacingBase: CGFloat = 1
    @ScaledMetric(relativeTo: .caption) private var incomeSpacingMin: CGFloat = 1
    @ScaledMetric(relativeTo: .caption) private var incomeFontBase: CGFloat = 8
    @ScaledMetric(relativeTo: .caption) private var incomeFontMin: CGFloat = 7
    @ScaledMetric(relativeTo: .caption) private var incomeStackBase: CGFloat = 20
    @ScaledMetric(relativeTo: .caption) private var incomeStackMin: CGFloat = 16
    @ScaledMetric(relativeTo: .subheadline) private var dayLabelBase: CGFloat = 16
    @ScaledMetric(relativeTo: .subheadline) private var dayLabelMin: CGFloat = 12
    @ScaledMetric(relativeTo: .caption) private var selectionSizeBase: CGFloat = 32
    @ScaledMetric(relativeTo: .caption) private var selectionSizeMin: CGFloat = 22
    private let minimumTextScale: CGFloat = 0.55

    func createContent() -> AnyView {
        let planned = summary?.planned ?? 0
        let actual = summary?.actual ?? 0
        let hasEvents = (planned + actual) > 0
        let spacing = max(daySpacingMin, daySpacingBase * scale)
        let incomeFont = max(incomeFontMin, incomeFontBase * scale)
        let incomeStackHeight = max(incomeStackMin, incomeStackBase * scale)
        let incomeSpacing = max(incomeSpacingMin, incomeSpacingBase * scale)

        var content: some View {
            VStack(spacing: spacing) {
                ZStack {
                    createSelectionView()
                    createRangeSelectionView()
                    createDayLabel()
                }
                VStack(spacing: incomeSpacing) {
                    if planned > 0 && actual > 0 {
                        Text(currencyString(planned))
                            .font(.system(size: incomeFont, weight: .regular))
                            .foregroundColor(DS.Colors.plannedIncome)
                            .lineLimit(1)
                            .minimumScaleFactor(minimumTextScale)
                            .allowsTightening(true)

                        Text(currencyString(actual))
                            .font(.system(size: incomeFont, weight: .regular))
                            .foregroundColor(DS.Colors.actualIncome)
                            .lineLimit(1)
                            .minimumScaleFactor(minimumTextScale)
                            .allowsTightening(true)
                    } else if planned > 0 {
                        Text(currencyString(planned))
                            .font(.system(size: incomeFont, weight: .regular))
                            .foregroundColor(DS.Colors.plannedIncome)
                            .lineLimit(1)
                            .minimumScaleFactor(minimumTextScale)
                            .allowsTightening(true)
                    } else if actual > 0 {
                        Text(currencyString(actual))
                            .font(.system(size: incomeFont, weight: .regular))
                            .foregroundColor(DS.Colors.actualIncome)
                            .lineLimit(1)
                            .minimumScaleFactor(minimumTextScale)
                            .allowsTightening(true)
                    }
                }
                // Reserve space so day numbers align even when income is absent
                .frame(height: incomeStackHeight, alignment: .top)
            }
            // Fill the available cell space and pin content to the top
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }

        if hasEvents {
            return AnyView(
                content
                    .accessibilityIdentifier("income_day_has_events_\(ymdString(date))")
            )
        } else {
            return AnyView(content)
        }
    }

    // Text: 16pt semibold; black in light, white in dark; flips on selection
    func createDayLabel() -> AnyView {
        let base = scheme == .dark ? Color.white : Color.black
        let selected = scheme == .dark ? Color.black : Color.white
        let color = isSelectedDay() ? selected : base
        return AnyView(
            Text(getStringFromDay(format: "d"))
                .font(.system(size: max(dayLabelMin, dayLabelBase * scale), weight: .semibold))
                .foregroundColor(color)
                .opacity(isCurrentMonth ? 1 : 0.28)
                .lineLimit(1)
                .minimumScaleFactor(minimumTextScale)
                .allowsTightening(true)
        )
    }

    // Selection circle: white in dark mode; black in light mode
    func createSelectionView() -> AnyView {
        let fill = scheme == .dark ? Color.white : Color.black
        let size = max(selectionSizeMin, selectionSizeBase * scale)
        return AnyView(
            Circle()
                .fill(fill)
                .frame(width: size, height: size)
                .opacity(isSelectedDay() ? 1 : 0)
        )
    }

    // We do not use range selection; return empty.
    func createRangeSelectionView() -> AnyView { AnyView(EmptyView()) }

    private func isSelectedDay() -> Bool {
        if let override = selectedOverride {
            return Calendar.current.isDate(override, inSameDayAs: date)
        }
        guard let selected = selectedDate?.wrappedValue else { return false }
        return Calendar.current.isDate(selected, inSameDayAs: date)
    }

    private func currencyString(_ amount: Double) -> String {
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.maximumFractionDigits = 0
        return nf.string(from: amount as NSNumber) ?? ""
    }

    private func ymdString(_ d: Date) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: d)
    }
}
