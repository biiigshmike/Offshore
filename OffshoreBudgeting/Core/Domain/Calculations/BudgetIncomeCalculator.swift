//
//  BudgetIncomeCalculator.swift
//  SoFar
//
//  Created by Michael Brown on 8/13/25.
//

import Foundation
import CoreData

// MARK: - BudgetIncomeCalculator
/// Computes income totals for a given date interval by querying Income globally.
/// No Budget↔Income relationship required.
struct BudgetIncomeCalculator {

    private static let sumKey = "totalAmount"
    private static let groupByKey = #keyPath(Income.isPlanned)

    // MARK: Fetch
    /// Returns all incomes intersecting the given date range.
    /// - Parameters:
    ///   - range: DateInterval for the budget window.
    ///   - isPlanned: Optional filter; pass true for planned only, false for actual only, nil for both.
    ///  - context: CoreData/App context
    static func fetchIncomes(in range: DateInterval,
                             isPlanned: Bool? = nil,
                             context: NSManagedObjectContext,
                             workspaceID: UUID) throws -> [Income] {
        let request = Income.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            predicate(for: range, isPlanned: isPlanned),
            WorkspaceService.predicate(for: workspaceID)
        ])
        request.fetchBatchSize = 64
        return try context.fetch(request)
    }

    // MARK: Sum
    /// Sums amounts within a date interval for planned or actual incomes.
    static func sum(in range: DateInterval,
                    isPlanned: Bool? = nil,
                    context: NSManagedObjectContext,
                    workspaceID: UUID) throws -> Double {
        let totals = try totals(for: range, context: context, workspaceID: workspaceID)
        if let planned = isPlanned {
            return planned ? totals.planned : totals.actual
        }
        return totals.planned + totals.actual
    }

    // MARK: Totals Bucket
    /// Convenience that returns both planned and actual totals for a budget window.
    static func totals(for range: DateInterval,
                       context: NSManagedObjectContext,
                       workspaceID: UUID) throws -> (planned: Double, actual: Double) {
        if !supportsGroupByFetches(context: context) {
            let incomes = try fetchIncomes(in: range, isPlanned: nil, context: context, workspaceID: workspaceID)
            var planned: Double = 0
            var actual: Double = 0
            for income in incomes {
                if income.isPlanned {
                    planned += income.amount
                } else {
                    actual += income.amount
                }
            }
            return (planned, actual)
        }

        let request = NSFetchRequest<NSDictionary>(entityName: "Income")
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            predicate(for: range, isPlanned: nil),
            WorkspaceService.predicate(for: workspaceID)
        ])
        request.resultType = .dictionaryResultType
        request.propertiesToGroupBy = [groupByKey]

        let sumExpression = NSExpressionDescription()
        sumExpression.name = sumKey
        sumExpression.expression = NSExpression(forFunction: "sum:", arguments: [NSExpression(forKeyPath: #keyPath(Income.amount))])
        sumExpression.expressionResultType = .doubleAttributeType

        request.propertiesToFetch = [groupByKey, sumExpression]

        let results = try context.fetch(request)

        var plannedTotal: Double = 0
        var actualTotal: Double = 0

        for entry in results {
            let rawTotal = entry[sumKey]
            let total = (rawTotal as? Double) ?? (rawTotal as? NSNumber)?.doubleValue ?? 0
            let plannedValue: Bool = {
                if let boolValue = entry[groupByKey] as? Bool {
                    return boolValue
                }
                if let numberValue = entry[groupByKey] as? NSNumber {
                    return numberValue.boolValue
                }
                return false
            }()

            if plannedValue {
                plannedTotal = total
            } else {
                actualTotal = total
            }
        }

        return (plannedTotal, actualTotal)
    }

    // MARK: Helpers
    private static func predicate(for range: DateInterval, isPlanned: Bool?) -> NSPredicate {
        var predicates: [NSPredicate] = [
            NSPredicate(format: "date >= %@ AND date <= %@", range.start as NSDate, range.end as NSDate)
        ]
        if let planned = isPlanned {
            predicates.append(NSPredicate(format: "isPlanned == %@", NSNumber(value: planned)))
        }
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    private static func supportsGroupByFetches(context: NSManagedObjectContext) -> Bool {
        let stores = context.persistentStoreCoordinator?.persistentStores ?? []
        return !stores.contains(where: { $0.type == NSInMemoryStoreType })
    }
}
