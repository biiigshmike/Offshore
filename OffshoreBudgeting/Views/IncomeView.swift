import SwiftUI
import CoreData
import MijickCalendarView
#if canImport(UIKit)
import UIKit
#endif

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
    @EnvironmentObject private var tour: GuidedTourState
    @Environment(\.managedObjectContext) private var moc
    @Environment(\.responsiveLayoutContext) private var layoutContext
    @Environment(\.guidedTourScreen) private var guidedTourScreen

    // MARK: Guided Tour State
    @State private var showTourOverlay = false
    @State private var activeHints: Set<IncomeHint> = []
    @State private var calendarReady = false

    private enum IncomeHint: String, CaseIterable, Hashable {
        case calendar
        case add

        var anchorID: String { "income.hint.\(rawValue)" }

        var icon: String {
            switch self {
            case .calendar: return "calendar"
            case .add: return "plus"
            }
        }

        var text: String {
            switch self {
            case .calendar:
                return "Use the arrow buttons to move between days or months."
            case .add:
                return "Tap the plus button to log planned or actual income."
            }
        }

        var arrowDirection: GuidedHintBubble.ArrowDirection {
            switch self {
            case .calendar: return .down
            case .add: return .down
            }
        }
    }

    // MARK: Body
    private var incomeContent: some View {
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
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    vm.delete(income: income, scope: .all)
                                } label: { Label("Delete", systemImage: "trash") }
                                .tint(.red)

                                Button {
                                    editingIncome = income
                                } label: { Label("Edit", systemImage: "pencil") }
                                .tint(.gray)
                            }
                    }
                }
            } header: {
                let date = vm.selectedDate ?? Date()
                VStack(alignment: .leading, spacing: 2) {
                    Text("Selected Day Income").font(.headline)
                    Text(DateFormatter.localizedString(from: date, dateStyle: .full, timeStyle: .none))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .textCase(nil)
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
        .navigationTitle("Income")
        .toolbar { toolbarContent }
        .onAppear {
            vm.reloadForSelectedDay(forceMonthReload: true)
            // Anchor the calendar to today on first appearance
            calendarScrollDate = normalize(Date())
            calendarReady = true
            evaluateIncomeTourState()
        }
        .onChange(of: vm.selectedDate) { _ in
            vm.reloadForSelectedDay(forceMonthReload: false)
        }
        .onChange(of: vm.incomesForDay) { _ in
            presentIncomeHintsIfNeeded()
        }
        .onChange(of: vm.eventsByDay) { _ in
            if !calendarReady {
                calendarReady = true
            }
            evaluateIncomeTourState()
        }
        .sheet(item: Binding(get: { addIncomeSheetDate.map { SheetDateBox(value: $0) } }, set: { addIncomeSheetDate = $0?.value })) {
            AddIncomeFormView(incomeObjectID: nil, budgetObjectID: nil, initialDate: $0.value)
        }
        .sheet(item: $editingIncome) { income in
            AddIncomeFormView(incomeObjectID: income.objectID, budgetObjectID: nil, initialDate: nil)
        }
        .onReceive(NotificationCenter.default.publisher(for: .guidedTourDidReset)) { _ in
            handleIncomeTourReset()
        }
    }

    var body: some View {
        ZStack {
            incomeContent
                .guidedHintOverlay { geometry, anchors in
                    incomeHintsOverlay(geometry: geometry, anchors: anchors)
                }

            if showTourOverlay {
                GuidedTourOverlay(
                    title: "Track your income",
                    message: incomeOverlayMessage,
                    bullets: incomeOverlayBullets,
                    onClose: handleIncomeOverlayDismiss
                )
                .transition(.opacity)
                .zIndex(1)
            }
        }
    }

    // MARK: Guided Tour
    private func evaluateIncomeTourState() {
        guard isIncomeViewActive, calendarReady else { return }

        if tour.needsOverlay(.income) {
            if !showTourOverlay {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showTourOverlay = true
                }
                AppLog.ui.info("GuidedTour overlayShown screen=income")
            }
            activeHints.removeAll()
            return
        }

        if showTourOverlay {
            showTourOverlay = false
        }

        presentIncomeHintsIfNeeded()
    }

    private func presentIncomeHintsIfNeeded() {
        guard isIncomeViewActive, calendarReady, !showTourOverlay else { return }

        guard tour.needsHints(.income) else {
            activeHints.removeAll()
            return
        }

        let hints = IncomeHint.allCases
        let desired = Set(hints)
        if desired != activeHints {
            activeHints = desired
            AppLog.ui.info("GuidedTour hintsShown screen=income count=\(desired.count)")
        }
    }

    private func handleIncomeOverlayDismiss() {
        tour.markOverlaySeen(.income)
        withAnimation(.easeInOut(duration: 0.25)) {
            showTourOverlay = false
        }
        AppLog.ui.info("GuidedTour overlayDismissed screen=income")
        presentIncomeHintsIfNeeded()
    }

    private func dismissIncomeHint(_ hint: IncomeHint) {
        activeHints.remove(hint)
        if activeHints.isEmpty {
            tour.markHintsDismissed(.income)
            AppLog.ui.info("GuidedTour hintsCompleted screen=income")
        }
    }

    private func handleIncomeTourReset() {
        showTourOverlay = false
        activeHints.removeAll()
        evaluateIncomeTourState()
    }

    private var isIncomeViewActive: Bool {
        guidedTourScreen == nil || guidedTourScreen == .income
    }

    private var incomeOverlayMessage: String {
        "Compare what you expected to receive with what actually arrived, and keep weekly totals in view."
    }

    private var incomeOverlayBullets: [String] {
        [
            "Use the calendar arrows to move between days or jump months.",
            "Selected Day lists every income entry for quick edits.",
            "The weekly summary shows planned versus actual totals."
        ]
    }

    @ViewBuilder
    private func incomeHintsOverlay(geometry: GeometryProxy, anchors: [String: Anchor<CGRect>]) -> some View {
        let orderedHints = IncomeHint.allCases.filter { activeHints.contains($0) }
        ForEach(orderedHints, id: \.self) { hint in
            if let frame = geometry.frame(forHint: hint.anchorID, anchors: anchors) {
                incomeHintBubble(for: hint, frame: frame, geometry: geometry)
            }
        }
    }

    @ViewBuilder
    private func incomeHintBubble(for hint: IncomeHint, frame: CGRect, geometry: GeometryProxy) -> some View {
        let bubble = GuidedHintBubble(
            icon: hint.icon,
            text: hint.text,
            arrowDirection: hint.arrowDirection
        ) { dismissIncomeHint(hint) }

        let position = incomeHintPosition(for: hint, frame: frame, geometry: geometry)

        bubble
            .position(x: position.x, y: position.y)
            .transition(.opacity.combined(with: .scale))
            .zIndex(1)
    }

    private func incomeHintPosition(for hint: IncomeHint, frame: CGRect, geometry: GeometryProxy) -> CGPoint {
        let width = geometry.size.width.isFinite ? geometry.size.width : UIScreen.main.bounds.width
        let minX: CGFloat = 120
        let maxX: CGFloat = max(minX, width - 120)
        let x = clamp(frame.midX, min: minX, max: maxX)

        switch hint {
        case .calendar:
            let y = max(frame.minY - 60, 60)
            return CGPoint(x: x, y: y)
        case .add:
            let y = max(frame.minY - 60, 60)
            return CGPoint(x: x, y: y)
        }
    }

    private func clamp(_ value: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
        guard min < max else { return value }
        if value < min { return min }
        if value > max { return max }
        return value
    }

    // MARK: Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            // Clear, no-background toolbar icon per design
            Buttons.toolbarIcon("plus") { addIncome() }
                .accessibilityLabel("Add Income")
                .accessibilityIdentifier("btn_add_income")
                .guidedHintAnchor(IncomeHint.add.anchorID)
        }
        if uiTest.showTestControls {
            ToolbarItem(placement: .navigationBarTrailing) {
                Buttons.toolbarIcon("trash") {
                    if let first = vm.incomesForDay.first { vm.delete(income: first, scope: .all) }
                }
                .accessibilityIdentifier("btn_delete_first_income")
            }
        }
    }

    // MARK: Calendar Section (in List row)

    private var calendarNav: some View {
        HStack(alignment: .center) {
            navIcon("chevron.backward.2") { goToPreviousMonth() }
            Spacer(minLength: 12)
            navIcon("chevron.backward") { goToPreviousDay() }
            Spacer(minLength: 12)
            navLabel("Today") { goToToday() }
            Spacer(minLength: 12)
            navIcon("chevron.forward") { goToNextDay() }
            Spacer(minLength: 12)
            navIcon("chevron.forward.2") { goToNextMonth() }
        }
        .frame(maxWidth: .infinity)
        .guidedHintAnchor(IncomeHint.calendar.anchorID)
    }

    @ViewBuilder
    private func navIcon(_ systemName: String, action: @escaping () -> Void) -> some View {
        if #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *) {
            Button(action: action) {
                Image(systemName: systemName)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .glassEffect(.regular.tint(.clear).interactive(true))
            }
            .buttonStyle(.plain)
            .buttonBorderShape(.circle)
            .tint(.accentColor)
        } else {
            Button(action: action) { Image(systemName: systemName) }
                .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func navLabel(_ title: String, action: @escaping () -> Void) -> some View {
        if #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *) {
            Button(action: action) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .frame(minWidth: 64, minHeight: 44)
                    .glassEffect(.regular.tint(.clear).interactive(true))
            }
            .buttonStyle(.plain)
            .buttonBorderShape(.circle)
            .tint(.accentColor)
        } else {
            Button(action: action) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .frame(minWidth: 64, minHeight: 33)
                    .padding(.horizontal, 10)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func navText(_ title: String, action: @escaping () -> Void) -> some View {
        if #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *) {
            Button(action: action) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .tint(.accentColor)
        } else {
            Button(action: action) { Text(title).font(.system(size: 15, weight: .semibold, design: .rounded)) }
                .buttonStyle(.plain)
        }
    }

    private var calendarView: some View {
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
                        selectedOverride: vm.selectedDate
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
        .frame(height: calendarHeight)
        .transaction { t in t.animation = nil; t.disablesAnimations = true }
    }

    private var calendarHeight: CGFloat {
        let containerWidth = layoutContext.containerSize.width
        guard containerWidth.isFinite, containerWidth > 0 else { return 335 }
        
        let horizontalInsets: CGFloat = 40
        let availableWidth = max(0, containerWidth - horizontalInsets)
        let dayDimension = max(35, (availableWidth / 7).rounded(.down))
        //let monthLabelHeight: CGFloat = 10
        let computedHeight = dayDimension * 4 //+ monthLabelHeight
        
        return max(335, computedHeight)
    }

    // MARK: Selected Day Section
    private var selectedDaySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            let date = vm.selectedDate ?? Date()
            Text("Selected Day Income")
                .font(.headline)
            Text(DateFormatter.localizedString(from: date, dateStyle: .full, timeStyle: .none))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if vm.incomesForDay.isEmpty {
                Text("No income for \(format(date)).")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                    .padding(.vertical, 4)
            } else {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(vm.incomesForDay, id: \.objectID) { income in
                        incomeRow(income)
                            .unifiedSwipeActions(.standard,
                                onEdit: { editingIncome = income },
                                onDelete: { vm.delete(income: income, scope: .all) })
                    }
                }
            }
        }
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
                Button("Delete") { vm.delete(income: income, scope: .all) }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("btn_delete_income_\(id)")
            }
        }
        .padding(.vertical, 6)
        .accessibilityIdentifier(rowAccessibilityID(for: income))
    }

    private func rowAccessibilityID(for income: Income) -> String {
        if let id = income.id?.uuidString { return "row_income_\(id)" }
        return "row_income"
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
    private func goToToday() { calendarScrollDate = normalize(Date()); vm.selectedDate = normalize(Date()) }

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
