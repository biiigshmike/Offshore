//
//  PresetsViewModel.swift (restored minimal)
//  OffshoreBudgeting
//
//  Provides PresetListItem and PresetsViewModel used by PresetsView and PresetRowView.
//

import SwiftUI
import CoreData

// MARK: - PresetListItem
/// Row view model for a global PlannedExpense template.
struct PresetListItem: Identifiable, Equatable {
    // MARK: Identity
    let id: UUID
    let template: PlannedExpense

    // MARK: Display
    let name: String
    let plannedAmount: Double
    let actualAmount: Double
    let assignedCount: Int
    let nextDate: Date?

    // MARK: Formatting Helpers
    var plannedCurrency: String { CurrencyFormatter.shared.string(plannedAmount) }
    var actualCurrency: String { CurrencyFormatter.shared.string(actualAmount) }
    var nextDateLabel: String {
        guard let d = nextDate else { return "Complete" }
        return DateFormatterCache.shared.mediumDate(d)
    }

    // MARK: Init
    init(template: PlannedExpense,
         plannedAmount: Double,
         actualAmount: Double,
         assignedCount: Int,
         nextDate: Date?) {
        self.id = template.id ?? UUID()
        self.template = template
        self.name = template.descriptionText ?? "Untitled"
        self.plannedAmount = plannedAmount
        self.actualAmount = actualAmount
        self.assignedCount = assignedCount
        self.nextDate = nextDate
    }
}

// MARK: - PresetsViewModel
@MainActor
final class PresetsViewModel: ObservableObject {
    @Published private(set) var items: [PresetListItem] = []
    private var changeMonitor: CoreDataEntityChangeMonitor?
    private var workspaceObserver: NSObjectProtocol?
    private var pendingApply: DispatchWorkItem?
    private var lastLoadedAt: Date? = nil

    // MARK: Start monitoring once
    func startIfNeeded(using context: NSManagedObjectContext) {
        guard changeMonitor == nil else { return }
        changeMonitor = CoreDataEntityChangeMonitor(
            entityNames: ["PlannedExpense"],
            debounceMilliseconds: DataChangeDebounce.milliseconds()
        ) { [weak self] in
            guard let self else { return }
            // Ensure main-actor hop for actor-isolated method
            Task { @MainActor in
                self.loadTemplates(using: context)
            }
        }
        if workspaceObserver == nil {
            workspaceObserver = NotificationCenter.default.addObserver(
                forName: .workspaceDidChange,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.loadTemplates(using: context)
                }
            }
        }
        loadTemplates(using: context)
    }

    /// Fetches global templates, deriving assignment counts and next dates.
    func loadTemplates(using context: NSManagedObjectContext) {
        let bg = CoreDataService.shared.newBackgroundContext()
        let workspaceID = WorkspaceService.shared.activeWorkspaceID

        Task {
            struct Outline { let id: NSManagedObjectID; let name: String; let planned: Double; let actual: Double; let assignedCount: Int; let nextDate: Date? }

            let outlines = await bg.perform { () -> [Outline] in
                let templates = PlannedExpenseService.shared.fetchGlobalTemplates(in: bg, workspaceID: workspaceID)
                let referenceDate = Calendar.current.startOfDay(for: Date())
                var rows: [Outline] = []
                for t in templates {
                    let children = PlannedExpenseService.shared.fetchChildren(of: t, in: bg, workspaceID: workspaceID)
                    let planned = t.plannedAmount
                    let actual = t.actualAmount
                    // Count distinct budgets to avoid over-reporting when duplicates exist
                    let assignedCount = Set(children.compactMap { $0.budget?.id }).count

                    var upcomingDates: [Date] = children
                        .compactMap { $0.transactionDate }
                        .filter { $0 >= referenceDate }
                    if let templateDate = t.transactionDate, templateDate >= referenceDate {
                        upcomingDates.append(templateDate)
                    }
                    let nextDate = upcomingDates.min()
                    let name = t.descriptionText ?? "Untitled"
                    rows.append(Outline(id: t.objectID, name: name, planned: planned, actual: actual, assignedCount: assignedCount, nextDate: nextDate))
                }
                return rows
            }

            await MainActor.run {
                var built: [PresetListItem] = []
                for o in outlines {
                    if let template = try? context.existingObject(with: o.id) as? PlannedExpense {
                        built.append(PresetListItem(template: template, plannedAmount: o.planned, actualAmount: o.actual, assignedCount: o.assignedCount, nextDate: o.nextDate))
                    }
                }
                let sorted = built.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                self.applyItemsDebounced(sorted)
            }
        }
    }

    // MARK: - Debounced apply (prevent flicker during CloudKit bursts)
    private func applyItemsDebounced(_ newItems: [PresetListItem]) {
        pendingApply?.cancel()
        var delayMS = DataChangeDebounce.milliseconds()
        if newItems.isEmpty {
            let now = Date()
            if let last = lastLoadedAt, now.timeIntervalSince(last) < 1.2 {
                delayMS = max(delayMS, 900)
            }
            #if canImport(UIKit)
            if (UserDefaultsAppSettingsStore().bool(for: .enableCloudSync) ?? false), CloudSyncMonitor.shared.isImporting {
                delayMS = max(delayMS, 1100)
            }
            #endif
        }
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.items = newItems
            if !newItems.isEmpty { self.lastLoadedAt = Date() }
        }
        pendingApply = work
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(delayMS), execute: work)
    }
    deinit {
        if let observer = workspaceObserver { NotificationCenter.default.removeObserver(observer) }
    }
}

// MARK: - Lightweight formatters
final class CurrencyFormatter {
    static let shared = CurrencyFormatter()
    private let nf: NumberFormatter
    private init() { let f = NumberFormatter(); f.numberStyle = .currency; f.maximumFractionDigits = 2; f.minimumFractionDigits = 2; nf = f }
    func string(_ value: Double) -> String { nf.string(from: NSNumber(value: value)) ?? "$0.00" }
}

final class DateFormatterCache {
    static let shared = DateFormatterCache()
    private let medium: DateFormatter
    private init() { let m = DateFormatter(); m.dateStyle = .medium; m.timeStyle = .none; medium = m }
    func mediumDate(_ date: Date) -> String { medium.string(from: date) }
}
