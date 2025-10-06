//
//  PlannedExpenseUpdateScope.swift
//  SoFar
//
//  Defines propagation scopes for planned expense updates so that templates
//  and their instantiated children can stay in sync consistently across the app.
//

import Foundation

/// Describes how edits to a planned expense should propagate through a template
/// hierarchy.
enum PlannedExpenseUpdateScope {
    /// Update only the targeted expense.
    case onlyThis
    /// Update the targeted expense plus instances with a transaction date on or before the reference date.
    case past(referenceDate: Date)
    /// Update the targeted expense plus instances with a transaction date on or after the reference date.
    case future(referenceDate: Date)
    /// Update the targeted expense plus all instances regardless of date.
    case all(referenceDate: Date)

    /// Returns the reference date associated with the scope, if any.
    var referenceDate: Date? {
        switch self {
        case .onlyThis:
            return nil
        case let .past(referenceDate),
             let .future(referenceDate),
             let .all(referenceDate):
            return referenceDate
        }
    }

    /// Indicates whether this scope should also update the template when the edit originates from a child.
    var includesTemplate: Bool {
        switch self {
        case .onlyThis:
            return false
        case .past, .future, .all:
            return true
        }
    }

    /// Determines whether a child with the given date should be updated for the scope.
    /// - Parameters:
    ///   - date: The child's transaction date.
    ///   - fallbackReferenceDate: A fallback reference date to use when the scope lacks one.
    /// - Returns: `true` if the child should be updated under this scope.
    func shouldIncludeChild(with date: Date?, fallbackReferenceDate: Date?) -> Bool {
        switch self {
        case .onlyThis:
            return false
        case .all:
            return true
        case let .future(referenceDate):
            let pivot = referenceDate ?? fallbackReferenceDate
            guard let pivot else { return true }
            guard let date else { return true }
            return date >= pivot
        case let .past(referenceDate):
            let pivot = referenceDate ?? fallbackReferenceDate
            guard let pivot else { return true }
            guard let date else { return true }
            return date <= pivot
        }
    }
}
