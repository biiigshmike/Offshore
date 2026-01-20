import Foundation
import CoreData

/// Stable, ID-only routes for value-based navigation.
///
/// Why this exists:
/// SwiftUI can evaluate view bodies frequently during scroll. If a `NavigationLink(value:)`
/// is driven by a value that changes (even within the same frame), SwiftUI can attempt to
/// update navigation multiple times per frame, producing warnings like:
/// "Update NavigationRequestObserver tried to update multiple times per frame."
///
/// `AppRoute` encodes destinations using only persistent identifiers (no titles, summaries,
/// colors, dates, or other derived/volatile data).
enum AppRoute: Hashable {
    // Home metric details (route identity = budget ID + destination case)
    case homeIncome(budgetID: NSManagedObjectID)
    case homeExpenseToIncome(budgetID: NSManagedObjectID)
    case homeSavingsOutlook(budgetID: NSManagedObjectID)
    case homeCategorySpotlight(budgetID: NSManagedObjectID)
    case homeDayOfWeek(budgetID: NSManagedObjectID)
    case homeCategoryAvailability(budgetID: NSManagedObjectID)
    case homeScenario(budgetID: NSManagedObjectID)

    // Home → Next Planned list
    case nextPlanned(budgetID: NSManagedObjectID)

    // Home → Card detail (stable identity only)
    case cardObjectIDURI(URL)
    case cardUUID(UUID)
}

