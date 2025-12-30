import SwiftUI
import CoreData

// MARK: - BudgetsView
/// Lists active budgets in reverse chronological order and links to details.
struct BudgetsView: View {
    // MARK: State
    @State private var budgets: [Budget] = []
    @State private var isLoading = false
    @State private var alert: AlertItem?
    @State private var isPresentingAddBudget = false
    @State private var isSearching = false
    @State private var searchText = ""
    @State private var expandedActive = true
    @State private var expandedUpcoming = false
    @State private var expandedPast = false
    @State private var ubiquitousObserver: NSObjectProtocol?
    @FocusState private var searchFocused: Bool
    @Environment(\.currentRootTab) private var currentRootTab

    // MARK: Services
    private let budgetService = BudgetService()

    var body: some View {
        content
            .navigationTitle("Budgets")
        .toolbar { toolbarContent }
        .task { await loadBudgetsIfNeeded() }
        .refreshable { await loadBudgets() }
        .onAppear {
            loadExpansionState()
            startObservingUbiquitousChangesIfNeeded()
        }
        .onDisappear {
            stopObservingUbiquitousChanges()
        }
        .alert(item: $alert) { alert in
            Alert(title: Text("Error"),
                  message: Text(alert.message),
                  dismissButton: .default(Text("OK")))
        }
        .tipsAndHintsOverlay(for: .budgets)
        .focusedSceneValue(
            \.newItemCommand,
            currentRootTab == .budgets ? NewItemCommand(title: "New Budget", action: { isPresentingAddBudget = true }) : nil
        )
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            ProgressView("Loading Budgets…")
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        } else if !isSearchActive && activeBudgets.isEmpty && upcomingBudgets.isEmpty && pastBudgets.isEmpty {
            UBEmptyState(message: "No budgets found. Tap + to create a budget.")
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .sheet(isPresented: $isPresentingAddBudget) { addBudgetSheet }
        } else {
            List {
                budgetSection(
                    title: "Active Budgets",
                    budgets: activeBudgets,
                    isExpanded: effectiveActiveExpanded,
                    onToggle: { toggleExpanded(.active) }
                )
                budgetSection(
                    title: "Upcoming Budgets",
                    budgets: upcomingBudgets,
                    isExpanded: effectiveUpcomingExpanded,
                    onToggle: { toggleExpanded(.upcoming) }
                )
                budgetSection(
                    title: "Past Budgets",
                    budgets: pastBudgets,
                    isExpanded: effectivePastExpanded,
                    onToggle: { toggleExpanded(.past) }
                )
            }
            .listStyle(.insetGrouped)
            .sheet(isPresented: $isPresentingAddBudget) { addBudgetSheet }
        }
    }

    // MARK: Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            searchToolbarControl
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Buttons.toolbarIcon("plus", label: "Add Budget") { isPresentingAddBudget = true }
        }
    }

    // MARK: Sheet
    private var addBudgetSheet: some View {
        let defaults = defaultBudgetDates()
        return AddBudgetView(
            initialStartDate: defaults.start,
            initialEndDate: defaults.end,
            onSaved: { Task { await loadBudgets() } }
        )
    }

    private var activeBudgets: [Budget] {
        let now = Date()
        return filteredBudgets.filter { isActive($0, on: now) }
    }

    private var pastBudgets: [Budget] {
        let now = Date()
        return filteredBudgets
            .filter { ($0.endDate ?? .distantFuture) < now }
            .sorted { ($0.endDate ?? .distantPast) > ($1.endDate ?? .distantPast) }
    }

    private var upcomingBudgets: [Budget] {
        let now = Date()
        return filteredBudgets
            .filter { ($0.startDate ?? .distantFuture) > now }
            .sorted { ($0.startDate ?? .distantFuture) < ($1.startDate ?? .distantFuture) }
    }

    // MARK: Data Loading
    private func loadBudgetsIfNeeded() async {
        guard budgets.isEmpty else { return }
        await loadBudgets()
    }

    private func loadBudgets() async {
        await MainActor.run { isLoading = true }
        do {
            let allBudgets = try budgetService.fetchAllBudgets(sortByStartDateDescending: true)
            await MainActor.run {
                budgets = allBudgets
                isLoading = false
                isPresentingAddBudget = false
            }
        } catch {
            await MainActor.run {
                alert = AlertItem(message: "Couldn’t load budgets. Please try again.")
                isLoading = false
            }
        }
    }

    private func isActive(_ budget: Budget, on date: Date) -> Bool {
        guard let start = budget.startDate, let end = budget.endDate else { return false }
        return start <= date && end >= date
    }

    private func defaultBudgetDates() -> (start: Date, end: Date) {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end = cal.date(byAdding: .day, value: 29, to: start) ?? start
        return (start, end)
    }

    // MARK: Search
    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isSearchActive: Bool {
        isSearching
    }

    private var filteredBudgets: [Budget] {
        let query = trimmedSearchText
        guard !query.isEmpty else { return budgets }
        return budgets.filter { matchesSearch($0, query: query) }
    }

    private func matchesSearch(_ budget: Budget, query: String) -> Bool {
        let title = (budget.name ?? "")
        let titleMatch = title.localizedCaseInsensitiveContains(query)
        guard looksDateish(query) else { return titleMatch }
        let dates = detectedDates(in: query)
        guard !dates.isEmpty else { return titleMatch }
        if dates.count == 1, let date = dates.first {
            return titleMatch || budgetContains(date: date, budget: budget)
        }
        guard let earliest = dates.min(), let latest = dates.max() else { return titleMatch }
        return titleMatch || budgetOverlaps(range: earliest...latest, budget: budget)
    }

    private func looksDateish(_ text: String) -> Bool {
        let lower = text.lowercased()
        if lower.range(of: #"(jan|feb|mar|apr|may|jun|jul|aug|sep|sept|oct|nov|dec)"#,
                       options: .regularExpression) != nil {
            return true
        }
        if lower.range(of: #"\d{1,4}[/-]\d{1,2}[/-]\d{1,4}"#, options: .regularExpression) != nil {
            return true
        }
        if lower.range(of: #"\d{1,2}[ .-]\d{1,2}[ .-]\d{2,4}"#, options: .regularExpression) != nil {
            return true
        }
        if (lower.contains("/") || lower.contains("-") || lower.contains(".")),
           lower.rangeOfCharacter(from: .decimalDigits) != nil {
            return true
        }
        return false
    }

    private func detectedDates(in text: String) -> [Date] {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else {
            return []
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return detector.matches(in: text, options: [], range: range).compactMap { $0.date }
    }

    private func budgetContains(date: Date, budget: Budget) -> Bool {
        guard let start = budget.startDate, let end = budget.endDate else { return false }
        return start <= date && end >= date
    }

    private func budgetOverlaps(range: ClosedRange<Date>, budget: Budget) -> Bool {
        guard let start = budget.startDate, let end = budget.endDate else { return false }
        return start <= range.upperBound && end >= range.lowerBound
    }

    // MARK: Section State
    private enum BudgetSectionKey {
        case active
        case upcoming
        case past
    }

    private var effectiveActiveExpanded: Bool { isSearchActive ? true : expandedActive }
    private var effectiveUpcomingExpanded: Bool { isSearchActive ? true : expandedUpcoming }
    private var effectivePastExpanded: Bool { isSearchActive ? true : expandedPast }

    private func toggleExpanded(_ key: BudgetSectionKey) {
        switch key {
        case .active:
            expandedActive.toggle()
            persistExpandedState(for: key, value: expandedActive)
        case .upcoming:
            expandedUpcoming.toggle()
            persistExpandedState(for: key, value: expandedUpcoming)
        case .past:
            expandedPast.toggle()
            persistExpandedState(for: key, value: expandedPast)
        }
    }

    // MARK: Section UI
    @ViewBuilder
    private func budgetSection(
        title: String,
        budgets: [Budget],
        isExpanded: Bool,
        onToggle: @escaping () -> Void
    ) -> some View {
        if isSearchActive || !budgets.isEmpty {
            Section(
                header: sectionHeader(title: title, count: budgets.count, isExpanded: isExpanded, onToggle: onToggle)
            ) {
                if isExpanded {
                    ForEach(budgets, id: \.objectID) { budget in
                        NavigationLink(destination: BudgetDetailsView(budgetID: budget.objectID)) {
                            BudgetRow(budget: budget)
                        }
                    }
                }
            }
        }
    }

    private func sectionHeader(
        title: String,
        count: Int,
        isExpanded: Bool,
        onToggle: @escaping () -> Void
    ) -> some View {
        Button(action: onToggle) {
            HStack(spacing: 8) {
                Text(sectionTitle(title: title, count: count))
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Image(systemName: "chevron.right")
                    .rotationEffect(isExpanded ? .degrees(90) : .zero)
                    .font(.system(size: 12, weight: .semibold))
                    .hideDecorative()
            }
        }
        .buttonStyle(.plain)
        .textCase(nil)
        .accessibilityValue(Text(isExpanded ? "Expanded" : "Collapsed"))
        .accessibilityHint(Text("Shows budgets in this section"))
    }

    private func sectionTitle(title: String, count: Int) -> String {
        guard isSearchActive else { return title }
        return "\(title): \(count) results"
    }

    // MARK: Toolbar Search
    @ViewBuilder
    private var searchToolbarControl: some View {
        if #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *) {
            searchToolbarControlGlass
        } else {
            searchToolbarControlLegacy
        }
    }

    @available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *)
    private var searchToolbarControlGlass: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 6) {
                if isSearching {
                    Buttons.toolbarIcon("xmark", label: "Close Search") { closeSearch() }
                    glassSearchField
                } else {
                    Buttons.toolbarIcon("magnifyingglass", label: "Search Budgets") { openSearch() }
                }
            }
        }
    }

    private var searchToolbarControlLegacy: some View {
        HStack(spacing: 6) {
            if isSearching {
                Buttons.toolbarIcon("xmark", label: "Close Search") { closeSearch() }
                legacySearchField
            } else {
                Buttons.toolbarIcon("magnifyingglass", label: "Search Budgets") { openSearch() }
            }
        }
    }

    @available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *)
    private var glassSearchField: some View {
        searchField
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.secondary.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.secondary.opacity(0.18), lineWidth: 0.5)
            )
    }

    private var legacySearchField: some View {
        searchField
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.secondary.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.secondary.opacity(0.18), lineWidth: 0.5)
            )
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            TextField("Search Budgets", text: $searchText)
                .textFieldStyle(.plain)
                .focused($searchFocused)
                .frame(minWidth: 140, maxWidth: 220)
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .iconButtonA11y(label: "Clear Search")
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func openSearch() {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
            isSearching = true
        }
        searchFocused = true
    }

    private func closeSearch() {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
            isSearching = false
        }
        searchText = ""
        searchFocused = false
    }

    // MARK: Expansion Persistence
    private var cloudEnabled: Bool {
        UserDefaults.standard.bool(forKey: AppSettingsKeys.enableCloudSync.rawValue)
    }

    private enum ExpansionStorageKey {
        static let activeLocal = "budgets.section.active.expanded.local"
        static let activeCloud = "budgets.section.active.expanded.cloud"
        static let upcomingLocal = "budgets.section.upcoming.expanded.local"
        static let upcomingCloud = "budgets.section.upcoming.expanded.cloud"
        static let pastLocal = "budgets.section.past.expanded.local"
        static let pastCloud = "budgets.section.past.expanded.cloud"
    }

    private func loadExpansionState() {
        expandedActive = loadExpandedValue(defaultValue: true,
                                           localKey: ExpansionStorageKey.activeLocal,
                                           cloudKey: ExpansionStorageKey.activeCloud)
        expandedUpcoming = loadExpandedValue(defaultValue: false,
                                             localKey: ExpansionStorageKey.upcomingLocal,
                                             cloudKey: ExpansionStorageKey.upcomingCloud)
        expandedPast = loadExpandedValue(defaultValue: false,
                                         localKey: ExpansionStorageKey.pastLocal,
                                         cloudKey: ExpansionStorageKey.pastCloud)
    }

    private func loadExpandedValue(defaultValue: Bool, localKey: String, cloudKey: String) -> Bool {
        let defaults = UserDefaults.standard
        if cloudEnabled {
            let kv = NSUbiquitousKeyValueStore.default
            if kv.object(forKey: cloudKey) != nil {
                let value = kv.bool(forKey: cloudKey)
                defaults.set(value, forKey: localKey)
                return value
            }
            if defaults.object(forKey: localKey) != nil {
                let value = defaults.bool(forKey: localKey)
                kv.set(value, forKey: cloudKey)
                kv.synchronize()
                return value
            }
        }
        if defaults.object(forKey: localKey) != nil {
            return defaults.bool(forKey: localKey)
        }
        return defaultValue
    }

    private func persistExpandedState(for key: BudgetSectionKey, value: Bool) {
        let defaults = UserDefaults.standard
        switch key {
        case .active:
            defaults.set(value, forKey: ExpansionStorageKey.activeLocal)
            syncExpandedValueIfNeeded(value, cloudKey: ExpansionStorageKey.activeCloud)
        case .upcoming:
            defaults.set(value, forKey: ExpansionStorageKey.upcomingLocal)
            syncExpandedValueIfNeeded(value, cloudKey: ExpansionStorageKey.upcomingCloud)
        case .past:
            defaults.set(value, forKey: ExpansionStorageKey.pastLocal)
            syncExpandedValueIfNeeded(value, cloudKey: ExpansionStorageKey.pastCloud)
        }
    }

    private func syncExpandedValueIfNeeded(_ value: Bool, cloudKey: String) {
        guard cloudEnabled else { return }
        let kv = NSUbiquitousKeyValueStore.default
        kv.set(value, forKey: cloudKey)
        kv.synchronize()
    }

    private func startObservingUbiquitousChangesIfNeeded() {
        guard cloudEnabled, ubiquitousObserver == nil else { return }
        ubiquitousObserver = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default,
            queue: .main
        ) { _ in
            loadExpansionState()
        }
    }

    private func stopObservingUbiquitousChanges() {
        if let observer = ubiquitousObserver {
            NotificationCenter.default.removeObserver(observer)
            ubiquitousObserver = nil
        }
    }
}

// MARK: - Row
private struct BudgetRow: View {
    let budget: Budget

    private let dateFormatter: DateIntervalFormatter = {
        let formatter = DateIntervalFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            if let start = budget.startDate, let end = budget.endDate {
                Text(dateFormatter.string(from: start, to: end))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var title: String {
        let raw = budget.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return raw.isEmpty ? "Untitled Budget" : raw
    }
}

private struct AlertItem: Identifiable {
    let id = UUID()
    let message: String
}
