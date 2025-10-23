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
    @AppStorage(AppSettingsKeys.confirmBeforeDelete.rawValue)
    private var confirmBeforeDelete: Bool = true

    @EnvironmentObject private var guidedWalkthrough: GuidedWalkthroughManager

    // MARK: Guided Walkthrough State
    @State private var showGuidedOverlay: Bool = false
    @State private var requestedGuidedWalkthrough: Bool = false
    @State private var visibleGuidedHints: Set<GuidedWalkthroughManager.Hint> = []
    @State private var guidedHintWorkItems: [GuidedWalkthroughManager.Hint: DispatchWorkItem] = [:]

    @State private var incomePendingDeletion: Income?
    @State private var isConfirmingDelete: Bool = false

    // MARK: Body
    var body: some View {
        ZStack {
            incomeContent
            if showGuidedOverlay, let overlay = guidedWalkthrough.overlay(for: .income) {
                GuidedOverlayView(
                    overlay: overlay,
                    onDismiss: {
                        showGuidedOverlay = false
                        guidedWalkthrough.markOverlaySeen(for: .income)
                    },
                    nextAction: presentIncomeHints
                )
                .transition(.opacity)
            }
        }
        .onAppear {
            requestIncomeGuidedIfNeeded()
            vm.reloadForSelectedDay(forceMonthReload: true)
            calendarScrollDate = normalize(Date())
        }
        .onDisappear { cancelIncomeHintWork() }
    }

    @ViewBuilder
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
                            .unifiedSwipeActions(
                                UnifiedSwipeConfig(allowsFullSwipeToDelete: !confirmBeforeDelete),
                                onEdit: { editingIncome = income },
                                onDelete: { requestDelete(income: income) }
                            )
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
        .overlay(alignment: .topTrailing) {
            if visibleGuidedHints.contains(.incomeEdit),
               let bubble = incomeHintLookup[.incomeEdit],
               !vm.incomesForDay.isEmpty {
                HintBubbleView(hint: bubble)
                    .padding(.top, 130)
                    .padding(.trailing, 20)
            }
        }
    }

    // MARK: Guided Walkthrough Helpers
    private var incomeHintLookup: [GuidedWalkthroughManager.Hint: HintBubble] {
        Dictionary(uniqueKeysWithValues: guidedWalkthrough.hints(for: .income).map { ($0.id, $0) })
    }

    private func requestIncomeGuidedIfNeeded() {
        guard !requestedGuidedWalkthrough else { return }
        requestedGuidedWalkthrough = true
        if guidedWalkthrough.shouldShowOverlay(for: .income) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showGuidedOverlay = true
            }
        } else {
            presentIncomeHints()
        }
    }

    private func presentIncomeHints() {
        for bubble in guidedWalkthrough.hints(for: .income) where guidedWalkthrough.shouldShowHint(bubble.id) {
            displayIncomeHint(bubble.id)
        }
    }

    private func displayIncomeHint(_ hint: GuidedWalkthroughManager.Hint) {
        guard guidedWalkthrough.shouldShowHint(hint) else { return }
        guard !visibleGuidedHints.contains(hint) else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            visibleGuidedHints.insert(hint)
        }
        scheduleIncomeHintAutoHide(for: hint)
    }

    private func scheduleIncomeHintAutoHide(for hint: GuidedWalkthroughManager.Hint) {
        guidedHintWorkItems[hint]?.cancel()
        let work = DispatchWorkItem {
            if visibleGuidedHints.contains(hint) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    visibleGuidedHints.remove(hint)
                }
            }
            guidedWalkthrough.markHintSeen(hint)
            guidedHintWorkItems[hint] = nil
        }
        guidedHintWorkItems[hint] = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0, execute: work)
    }

    private func hideIncomeHint(_ hint: GuidedWalkthroughManager.Hint) {
        if let work = guidedHintWorkItems.removeValue(forKey: hint) {
            work.cancel()
        }
        if visibleGuidedHints.contains(hint) {
            withAnimation(.easeInOut(duration: 0.2)) {
                visibleGuidedHints.remove(hint)
            }
        }
        guidedWalkthrough.markHintSeen(hint)
    }

    private func cancelIncomeHintWork() {
        for (_, work) in guidedHintWorkItems { work.cancel() }
        guidedHintWorkItems.removeAll()
        visibleGuidedHints.removeAll()
        showGuidedOverlay = false
    }

    // MARK: Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            // Clear, no-background toolbar icon per design
            Buttons.toolbarIcon("plus") {
                hideIncomeHint(.incomeAdd)
                addIncome()
            }
            .accessibilityLabel("Add Income")
            .accessibilityIdentifier("btn_add_income")
            .overlay(alignment: .topTrailing) {
                if visibleGuidedHints.contains(.incomeAdd),
                   let bubble = incomeHintLookup[.incomeAdd] {
                    HintBubbleView(hint: bubble)
                        .offset(x: 16, y: -50)
                }
            }
            .simultaneousGesture(TapGesture().onEnded { hideIncomeHint(.incomeAdd) })
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
                            .unifiedSwipeActions(
                                UnifiedSwipeConfig(allowsFullSwipeToDelete: !confirmBeforeDelete),
                                onEdit: { editingIncome = income },
                                onDelete: { requestDelete(income: income) }
                            )
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
                Button("Delete") { requestDelete(income: income) }
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
