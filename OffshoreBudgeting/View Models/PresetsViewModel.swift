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

    /// Fetches global templates, deriving assignment counts and next dates.
    func loadTemplates(using context: NSManagedObjectContext) {
        let bg = CoreDataService.shared.newBackgroundContext()

        Task {
            struct Outline { let id: NSManagedObjectID; let name: String; let planned: Double; let actual: Double; let assignedCount: Int; let nextDate: Date? }

            let outlines = await bg.perform { () -> [Outline] in
                let templates = PlannedExpenseService.shared.fetchGlobalTemplates(in: bg)
                let referenceDate = Calendar.current.startOfDay(for: Date())
                var rows: [Outline] = []
                for t in templates {
                    let children = PlannedExpenseService.shared.fetchChildren(of: t, in: bg)
                    let planned = t.plannedAmount
                    let actual = t.actualAmount
                    let assignedCount = children.count

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
                self.items = built.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            }
        }
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

