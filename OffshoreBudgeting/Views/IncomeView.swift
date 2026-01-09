import SwiftUI
import CoreData
import MijickCalendarView

// MARK: - IncomeView2
/// Simplified Income screen built with plain SwiftUI primitives.
/// Sections:
/// 1) Calendar with nav controls (<< < Today > >>)
/// 2) Selected Day's Income (list with swipe for edit/delete)
/// 3) Weekly totals (Sun–Sat) showing Planned/Actual with dates
struct IncomeView: View {

    // MARK: State & ViewModel
    @StateObject private var vm = IncomeScreenViewModel()
    @Environment(\.uiTestingFlags) private var uiTest

    // Scroll-specific state for programmatic calendar scrolling
    @State private var calendarScrollDate: Date? = nil

    // MARK: Sheet State
    @State private var addIncomeSheetDate: Date? = nil
    @State private var editingIncome: Income? = nil

    // MARK: Environment
    @Environment(\.managedObjectContext) private var moc
    @Environment(\.responsiveLayoutContext) private var layoutContext
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @AppStorage(AppSettingsKeys.confirmBeforeDelete.rawValue)
    private var confirmBeforeDelete: Bool = true

    // Guided walkthrough removed

    @State private var incomePendingDeletion: Income?
    @State private var isConfirmingDelete: Bool = false

    // MARK: Layout
    @ScaledMetric(relativeTo: .body) private var calendarNavButtonSize: CGFloat = 44
    @ScaledMetric(relativeTo: .body) private var calendarNavLabelMinWidth: CGFloat = 64
    @ScaledMetric(relativeTo: .body) private var calendarNavSpacing: CGFloat = 12
    @ScaledMetric(relativeTo: .body) private var minCalendarHeightCompact: CGFloat = 260
    @ScaledMetric(relativeTo: .body) private var minCalendarHeightRegular: CGFloat = 320
    @ScaledMetric(relativeTo: .body) private var calendarHeaderHeight: CGFloat = 64
    @ScaledMetric(relativeTo: .body) private var calendarHeightScale: CGFloat = 1
    @ScaledMetric(relativeTo: .body) private var weekHeaderSpacing: CGFloat = 8
    @ScaledMetric(relativeTo: .body) private var weekCellSpacing: CGFloat = 6
    @ScaledMetric(relativeTo: .body) private var weekCellPadding: CGFloat = 6
    @ScaledMetric(relativeTo: .body) private var weekCellMinHeight: CGFloat = 84
    @ScaledMetric(relativeTo: .body) private var weekCellCornerRadius: CGFloat = 8
    @ScaledMetric(relativeTo: .body) private var weekCellInnerSpacing: CGFloat = 4

    // MARK: Body
    var body: some View {
        incomeContent
        .onAppear {
            vm.reloadForSelectedDay(forceMonthReload: true)
            calendarScrollDate = normalize(Date())
        }
        .onChange(of: layoutContext.isLandscape) { _ in
            calendarScrollDate = normalize(vm.selectedDate ?? Date())
        }
        .tipsAndHintsOverlay(for: .income)
        
    }

    @ViewBuilder
    private var incomeContent: some View {
        Group {
            if useSplitLayout {
                ZStack {
                    splitPageBackground.ignoresSafeArea()
                    splitIncomeContent
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            } else {
                listIncomeContent
            }
        }
        .navigationTitle("Income")
        .ub_windowTitle("Income")
        .toolbar { toolbarContent }
        .refreshable {
            refreshSelectedDay()
        }
        .onChange(of: vm.selectedDate) { _ in
            vm.reloadForSelectedDay(forceMonthReload: false)
        }
        .sheet(item: Binding(get: { addIncomeSheetDate.map { SheetDateBox(value: $0) } }, set: { addIncomeSheetDate = $0?.value })) {
            AddIncomeFormView(incomeObjectID: nil, budgetObjectID: nil, initialDate: $0.value)
        }
        .sheet(item: $editingIncome) { income in
            AddIncomeFormView(incomeObjectID: income.objectID, budgetObjectID: nil, initialDate: nil)
        }
        .alert("Delete Income?", isPresented: $isConfirmingDelete) {
            Button("Delete", role: .destructive) { confirmDeleteIfNeeded() }
            Button("Cancel", role: .cancel) {
                incomePendingDeletion = nil
                isConfirmingDelete = false
            }
        } message: {
            Text("This will remove the income entry.")
        }
        
    }

    // Guided walkthrough removed

    // MARK: Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            // Clear, no-background toolbar icon per design
            Buttons.toolbarIcon("plus") { addIncome() }
            .accessibilityLabel("Add Income")
            .accessibilityIdentifier("btn_add_income")
            
        }
        if uiTest.showTestControls {
            ToolbarItem(placement: .navigationBarTrailing) {
                Buttons.toolbarIcon("trash") {
                    if let first = vm.incomesForDay.first { requestDelete(income: first) }
                }
                .accessibilityIdentifier("btn_delete_first_income")
            }
        }
    }

    // MARK: Calendar Section (in List row)

    @ViewBuilder
    private var calendarNav: some View {
        if dynamicTypeSize.isAccessibilitySize {
            calendarNavWrapped
        } else {
            calendarNavRow
        }
    }

    private var calendarNavRow: some View {
        HStack(alignment: .center) {
            navIcon("chevron.backward.2") { goToPreviousMonth() }
            Spacer(minLength: calendarNavSpacing)
            navIcon("chevron.backward") { goToPreviousDay() }
            Spacer(minLength: calendarNavSpacing)
            navIcon("circle.fill") { goToToday() }
            Spacer(minLength: calendarNavSpacing)
            navIcon("chevron.forward") { goToNextDay() }
            Spacer(minLength: calendarNavSpacing)
            navIcon("chevron.forward.2") { goToNextMonth() }
        }
        .frame(maxWidth: .infinity)
    }

    private var calendarNavWrapped: some View {
        VStack(spacing: DS.Spacing.s) {
            HStack {
                navIcon("chevron.backward.2") { goToPreviousMonth() }
                navIcon("circle.fill") { goToToday() }
                navIcon("chevron.forward.2") { goToNextMonth() }
            }
            HStack {
                navIcon("chevron.backward") { goToPreviousWeek() }
                Spacer(minLength: calendarNavSpacing)
                navIcon("chevron.forward") { goToNextWeek() }
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func navIcon(_ systemName: String, action: @escaping () -> Void) -> some View {
        let symbolFont = Font.title3.weight(.semibold)
        if #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *) {
            Button(action: action) {
                Image(systemName: systemName)
                    .font(symbolFont)
                    .frame(width: calendarNavButtonSize, height: calendarNavButtonSize)
                    .glassEffect(.regular.tint(.clear).interactive(true))
            }
            .buttonStyle(.plain)
            .buttonBorderShape(.circle)
            .tint(.accentColor)
        } else {
            Button(action: action) {
                Image(systemName: systemName)
                    .font(symbolFont)
                    .frame(width: calendarNavButtonSize, height: calendarNavButtonSize)
                    .contentShape(Circle())
            }
                .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func navLabel(_ title: String, action: @escaping () -> Void) -> some View {
        let labelFont = Font.subheadline.weight(.semibold)
        let minWidth = dynamicTypeSize.isAccessibilitySize ? 0 : calendarNavLabelMinWidth
        if #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *) {
            Button(action: action) {
                Text(title)
                    .font(labelFont)
                    .frame(minWidth: minWidth, minHeight: calendarNavButtonSize)
                    .glassEffect(.regular.tint(.clear).interactive(true))
            }
            .buttonStyle(.plain)
            .buttonBorderShape(.circle)
            .tint(.accentColor)
        } else {
            Button(action: action) {
                Text(title)
                    .font(labelFont)
                    .frame(minWidth: minWidth, minHeight: calendarNavButtonSize)
                    .padding(.horizontal, 10)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func navText(_ title: String, action: @escaping () -> Void) -> some View {
        let labelFont = Font.subheadline.weight(.semibold)
        if #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *) {
            Button(action: action) {
                Text(title)
                    .font(labelFont)
                    .frame(width: calendarNavButtonSize, height: calendarNavButtonSize)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .tint(.accentColor)
        } else {
            Button(action: action) {
                Text(title)
                    .font(labelFont)
                    .frame(width: calendarNavButtonSize, height: calendarNavButtonSize)
                    .contentShape(Circle())
            }
                .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var calendarView: some View {
        if dynamicTypeSize.isAccessibilitySize {
            accessibilityWeekCalendar
        } else {
            monthCalendarView
        }
    }

    private var monthCalendarView: some View {
        let today = Date()
        let cal = sundayFirstCalendar
        let start = cal.date(byAdding: .year, value: -5, to: today)!
        let end = cal.date(byAdding: .year, value: 5, to: today)!

        return MCalendarView(
            selectedDate: Binding(get: { vm.selectedDate ?? Date() }, set: { vm.selectedDate = $0 }),
            selectedRange: .constant(nil)
        ) { config in
            var resolved = config
                .dayView { date, isCurrentMonth, selectedDate, selectedRange in
                    UBDayView(
                        date: date,
                        isCurrentMonth: isCurrentMonth,
                        selectedDate: selectedDate,
                        selectedRange: selectedRange,
                        summary: vm.summary(for: date),
                        selectedOverride: vm.selectedDate,
                        scale: calendarSizing.dayScale
                    )
                }
                .firstWeekday(.sunday)
                .monthLabel(UBMonthLabel.init)
                .startMonth(start)
                .endMonth(end)

            if let target = calendarScrollDate {
                resolved = resolved.scrollTo(date: target)
                // Clear the target after applying to avoid repeated jumps
                DispatchQueue.main.async { calendarScrollDate = nil }
            }

            return resolved
        }
        .frame(height: calendarSizing.height)
        .frame(maxWidth: calendarSizing.maxWidth)
        .frame(maxWidth: .infinity, alignment: .center)
        .transaction { t in t.animation = nil; t.disablesAnimations = true }
    }

    private var accessibilityWeekCalendar: some View {
        let selected = vm.selectedDate ?? Date()
        let weekDates = weekDates(for: selected)
        let weekRange = weekBounds(for: selected)
        return VStack(alignment: .leading, spacing: weekHeaderSpacing) {
            Text(monthTitle(for: selected))
                .font(.headline)
            Text("\(format(weekRange.start)) – \(format(weekRange.end))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            VStack(spacing: weekCellSpacing) {
                ForEach(weekDates, id: \.self) { date in
                    weekDayRow(date: date)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func weekDayRow(date: Date) -> some View {
        let summary = vm.summary(for: date)
        let isSelected = Calendar.current.isDate(vm.selectedDate ?? date, inSameDayAs: date)
        let planned = summary?.planned ?? 0
        let actual = summary?.actual ?? 0
        return Button(action: { vm.selectedDate = normalize(date) }) {
            HStack(alignment: .top, spacing: weekCellInnerSpacing) {
                VStack(alignment: .leading, spacing: weekCellInnerSpacing) {
                    Text(DateFormatter.localizedString(from: date, dateStyle: .full, timeStyle: .none))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    if planned > 0 {
                        Text("Planned \(vm.currencyString(for: planned))")
                            .font(.caption)
                            .foregroundStyle(DS.Colors.plannedIncome)
                    }
                    if actual > 0 {
                        Text("Actual \(vm.currencyString(for: actual))")
                            .font(.caption)
                            .foregroundStyle(DS.Colors.actualIncome)
                    }
                    if planned <= 0 && actual <= 0 {
                        Text("No income")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(weekCellPadding)
            .background(
                RoundedRectangle(cornerRadius: weekCellCornerRadius, style: .continuous)
                    .fill(isSelected ? Color.primary.opacity(0.12) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: weekCellCornerRadius, style: .continuous)
                    .stroke(isSelected ? Color.primary.opacity(0.35) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(weekDayAccessibilityLabel(for: date, planned: planned, actual: actual))
        .accessibilityHint("Select day")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func weekDates(for date: Date) -> [Date] {
        let cal = sundayFirstCalendar
        let start = cal.dateInterval(of: .weekOfYear, for: date)?.start ?? date
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }

    private func monthTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM y"
        return formatter.string(from: date)
    }

    private func weekDayAccessibilityLabel(for date: Date, planned: Double, actual: Double) -> String {
        let dateText = DateFormatter.localizedString(from: date, dateStyle: .full, timeStyle: .none)
        if planned <= 0 && actual <= 0 {
            return "\(dateText), no income"
        }
        if planned > 0 && actual > 0 {
            return "\(dateText), planned \(vm.currencyString(for: planned)), actual \(vm.currencyString(for: actual))"
        }
        if planned > 0 {
            return "\(dateText), planned \(vm.currencyString(for: planned))"
        }
        return "\(dateText), actual \(vm.currencyString(for: actual))"
    }

    private struct CalendarSizing {
        let maxWidth: CGFloat
        let height: CGFloat
        let dayScale: CGFloat
    }

    private var calendarSizing: CalendarSizing {
        let container = layoutContext.containerSize
        let heightScale = calendarHeightScale
        guard container.width.isFinite, container.width > 0, container.height.isFinite, container.height > 0 else {
            return CalendarSizing(maxWidth: .infinity, height: max(minCalendarHeight, 335 * heightScale), dayScale: 1)
        }

        if isPhonePortraitLayout {
            let horizontalInsets: CGFloat = dynamicTypeSize.isAccessibilitySize ? 20 : 40
            let availableWidth = max(0, container.width - horizontalInsets)
            let dayDimension = max(35, (availableWidth / 7).rounded(.down))
            let computedHeight = dayDimension * 4 * heightScale
            return CalendarSizing(
                maxWidth: availableWidth,
                height: max(minCalendarHeight, computedHeight),
                dayScale: 1
            )
        }

        let panelWidth = calendarPanelWidth(in: container)
        let targetHeight = targetCalendarHeight(in: container)
        let headerHeight: CGFloat = calendarHeaderHeight
        let dayDimension = max(28, min(panelWidth / 7, (targetHeight - headerHeight) / 6))
        let calendarWidth = min(panelWidth, dayDimension * 7)
        let calendarHeight = max(minCalendarHeight, dayDimension * 6 * heightScale + headerHeight)
        let scaleBase = min(1.0, max(0.75, dayDimension / 46))
        let scale = dynamicTypeSize.isAccessibilitySize ? min(scaleBase, 0.7) : scaleBase

        return CalendarSizing(maxWidth: calendarWidth, height: calendarHeight, dayScale: scale)
    }

    private var minCalendarHeight: CGFloat {
        layoutContext.verticalSizeClass == .compact ? minCalendarHeightCompact : minCalendarHeightRegular
    }

    private func calendarPanelWidth(in container: CGSize) -> CGFloat {
        let horizontalInsets: CGFloat = useSplitLayout ? 20 : 40
        let spacing = useSplitLayout ? splitPanelSpacing : 0
        let available = max(0, container.width - horizontalInsets * 2 - spacing)
        return useSplitLayout ? available / 2 : available
    }

    private func targetCalendarHeight(in container: CGSize) -> CGFloat {
        let isMac = layoutContext.idiom == .mac
        let splitRatio: CGFloat = isMac ? 0.72 : 0.58
        let base = container.height * (useSplitLayout ? splitRatio : 0.52)
        let maxHeight: CGFloat = (useSplitLayout ? (isMac ? 760 : 520) : 560) * calendarHeightScale
        return min(max(base, minCalendarHeight), maxHeight)
    }

    private var splitPanelSpacing: CGFloat { 16 }
    private var splitPanelHeight: CGFloat {
        guard useSplitLayout else { return calendarSizing.height }
        let topPadding: CGFloat = 12
        let navHeight: CGFloat = calendarNavButtonSize
        let spacing: CGFloat = 8
        return calendarSizing.height + topPadding + navHeight + spacing
    }
    private var useSplitLayout: Bool {
        guard layoutContext.isLandscape else { return false }
        if layoutContext.idiom == .mac { return true }
        if layoutContext.verticalSizeClass == .compact { return true }
        return layoutContext.horizontalSizeClass == .regular
    }

    private var isPhonePortraitLayout: Bool {
        !layoutContext.isLandscape
            && layoutContext.horizontalSizeClass == .compact
            && layoutContext.verticalSizeClass == .regular
    }

    // MARK: Layout Variants
    private var listIncomeContent: some View {
        List {
            // Calendar section as a single row
            VStack(alignment: .leading, spacing: 12) {
                calendarNav
                calendarView
            }
            .listRowInsets(EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20))

            // Selected Day Income section
            Section {
                if vm.incomesForDay.isEmpty {
                    let date = vm.selectedDate ?? Date()
                    Text("No income for \(format(date)).")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                        .padding(.vertical, 4)
                } else {
                    ForEach(vm.incomesForDay, id: \.objectID) { income in
                        incomeRow(income)
                            .unifiedSwipeActions(
                                UnifiedSwipeConfig(allowsFullSwipeToDelete: !confirmBeforeDelete),
                                onEdit: { editingIncome = income },
                                onDelete: { requestDelete(income: income) }
                            )
                    }
                }
            } header: {
                selectedDayHeaderView
            }

            // Weekly totals section
            Section {
                let (start, end) = weekBounds(for: vm.selectedDate ?? Date())
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .lastTextBaseline) {
                        totalsColumn(label: "Planned", amount: vm.plannedTotalForSelectedWeek, color: DS.Colors.plannedIncome)
                        Spacer(minLength: 0)
                        totalsColumn(label: "Actual", amount: vm.actualTotalForSelectedWeek, color: DS.Colors.actualIncome)
                    }
                    Text("\(format(start)) – \(format(end))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
            } header: {
                Text("Week Total Income").font(.headline).textCase(nil)
            }
        }
    }

    private var splitIncomeContent: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: splitPanelSpacing) {
                calendarPanel
                    .frame(height: splitPanelHeight)
                    .modifier(IncomeSplitCellModifier(background: splitCellBackground))
                selectedDayPanel
                    .frame(height: splitPanelHeight)
                    .modifier(IncomeSplitCellModifier(background: splitCellBackground))
            }
            .frame(maxWidth: .infinity, alignment: .top)

            weeklyTotalsSection
                .modifier(IncomeSplitCellModifier(background: splitCellBackground))
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private var calendarPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            calendarNav
                .padding(.top, useSplitLayout ? 12 : 0)
            calendarView
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var selectedDayPanel: some View {
        List {
            Section(header: selectedDayHeaderView) {
                if vm.incomesForDay.isEmpty {
                    let date = vm.selectedDate ?? Date()
                    Text("No income for \(format(date)).")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                        .padding(.vertical, 4)
                } else {
                    ForEach(vm.incomesForDay, id: \.objectID) { income in
                        incomeRow(income)
                            .unifiedSwipeActions(
                                UnifiedSwipeConfig(allowsFullSwipeToDelete: !confirmBeforeDelete),
                                onEdit: { editingIncome = income },
                                onDelete: { requestDelete(income: income) }
                            )
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .scrollContentBackground(.hidden)
        .refreshable {
            refreshSelectedDay()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private struct IncomeSplitCellModifier: ViewModifier {
        let background: Color

        func body(content: Content) -> some View {
            content
                .padding(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(
                    RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                        .fill(background)
                )
        }
    }

    private var splitCellBackground: Color {
        Color(UIColor.systemBackground)
    }

    private var splitPageBackground: Color {
        if #available(iOS 13.0, macCatalyst 13.0, *) {
            return Color(UIColor.systemGroupedBackground)
        } else {
            return Color(UIColor(white: 0.94, alpha: 1.0))
        }
    }

    // MARK: Selected Day Header
    private var selectedDayHeaderView: some View {
        let date = vm.selectedDate ?? Date()
        return VStack(alignment: .leading, spacing: 2) {
            Text("Selected Day Income").font(.headline)
            Text(DateFormatter.localizedString(from: date, dateStyle: .full, timeStyle: .none))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .textCase(nil)
    }

    // MARK: Weekly Totals Section
    private var weeklyTotalsSection: some View {
        let (start, end) = weekBounds(for: vm.selectedDate ?? Date())
        return VStack(alignment: .leading, spacing: 8) {
            Text("Week Total Income").font(.headline)
            HStack(alignment: .lastTextBaseline) {
                totalsColumn(label: "Planned", amount: vm.plannedTotalForSelectedWeek, color: DS.Colors.plannedIncome)
                Spacer(minLength: 0)
                totalsColumn(label: "Actual", amount: vm.actualTotalForSelectedWeek, color: DS.Colors.actualIncome)
            }
            Text("\(format(start)) – \(format(end))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: Subviews
    private func incomeRow(_ income: Income) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(income.source ?? "—").font(.headline)
                Text(vm.currencyString(for: income.amount)).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            if uiTest.showTestControls, let id = income.id?.uuidString {
                Button("Delete") { requestDelete(income: income) }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("btn_delete_income_\(id)")
            }
        }
        .padding(.vertical, 6)
        .accessibilityIdentifier(rowAccessibilityID(for: income))
    }

    private func rowAccessibilityID(for income: Income) -> String {
        AccessibilityRowIdentifier.incomeRow(id: income.id)
    }

    private func totalsColumn(label: String, amount: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.subheadline).foregroundStyle(.secondary)
            Text(vm.currencyString(for: amount)).font(.title3.weight(.semibold)).foregroundStyle(color)
        }
    }

    // MARK: Actions
    private func addIncome() { addIncomeSheetDate = vm.selectedDate ?? Date() }
    private func goToPreviousMonth() { adjustMonth(by: -1) }
    private func goToNextMonth() { adjustMonth(by: 1) }
    private func goToPreviousDay() { adjustDay(by: -1) }
    private func goToNextDay() { adjustDay(by: 1) }
    private func goToPreviousWeek() { adjustWeek(by: -1) }
    private func goToNextWeek() { adjustWeek(by: 1) }
    private func goToToday() { calendarScrollDate = normalize(Date()); vm.selectedDate = normalize(Date()) }
    private func refreshSelectedDay() {
        // Pull-to-refresh: nudge CloudKit and reload the selected day
        CloudSyncAccelerator.shared.nudgeOnForeground()
        vm.reloadForSelectedDay(forceMonthReload: true)
    }

    private func adjustDay(by delta: Int) {
        let base = vm.selectedDate ?? Date()
        if let next = Calendar.current.date(byAdding: .day, value: delta, to: base) {
            vm.selectedDate = normalize(next); calendarScrollDate = vm.selectedDate
        }
    }

    private func adjustMonth(by delta: Int) {
        let base = vm.selectedDate ?? Date()
        let cal = Calendar.current
        if let startOfCurrent = cal.date(from: cal.dateComponents([.year, .month], from: base)),
           let next = cal.date(byAdding: .month, value: delta, to: startOfCurrent) {
            vm.selectedDate = normalize(next); calendarScrollDate = vm.selectedDate
        }
    }

    private func adjustWeek(by delta: Int) {
        let base = vm.selectedDate ?? Date()
        let cal = Calendar.current
        if let next = cal.date(byAdding: .weekOfYear, value: delta, to: base) {
            vm.selectedDate = normalize(next); calendarScrollDate = vm.selectedDate
        }
    }

    private func requestDelete(income: Income) {
        if confirmBeforeDelete {
            incomePendingDeletion = income
            isConfirmingDelete = true
        } else {
            delete(income: income)
        }
    }

    private func confirmDeleteIfNeeded() {
        guard let pending = incomePendingDeletion else {
            isConfirmingDelete = false
            return
        }
        isConfirmingDelete = false
        delete(income: pending)
    }

    private func delete(income: Income) {
        vm.delete(income: income, scope: .all)
        isConfirmingDelete = false
        incomePendingDeletion = nil
    }

    // MARK: Helpers
    private var sundayFirstCalendar: Calendar {
        var c = Calendar.current; c.firstWeekday = 1; return c
    }
    private func normalize(_ date: Date) -> Date { Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: date) ?? date }
    private func weekBounds(for date: Date) -> (start: Date, end: Date) {
        let cal = sundayFirstCalendar
        let start = cal.dateInterval(of: .weekOfYear, for: date)?.start ?? date
        let end = cal.date(byAdding: .day, value: 6, to: start) ?? date
        return (start, end)
    }
    private func format(_ date: Date) -> String { let f = DateFormatter(); f.dateStyle = .medium; return f.string(from: date) }

    // MARK: Sheet Box
    private struct SheetDateBox: Identifiable {
        let value: Date
        var id: Date { value }
    }
}
//
