//
//  AddVariableExpenseView.swift
//  OffshoreBudgeting
//
//  Wrapper around the existing AddUnplannedExpenseView that exposes
//  navigation-friendly configuration for sidebar routes.
//

import SwiftUI
import CoreData

// MARK: - AddVariableExpenseView
struct AddVariableExpenseView: View {

    // MARK: Inputs
    private let unplannedExpenseID: NSManagedObjectID?
    private let allowedCardIDs: Set<NSManagedObjectID>?
    private let initialCardID: NSManagedObjectID?
    private let initialDate: Date?
    private let onSaved: () -> Void
    private let includeNavigationContainer: Bool

    // MARK: Init
    init(
        unplannedExpenseID: NSManagedObjectID? = nil,
        allowedCardIDs: Set<NSManagedObjectID>? = nil,
        initialCardID: NSManagedObjectID? = nil,
        initialDate: Date? = nil,
        onSaved: @escaping () -> Void = {},
        includeNavigationContainer: Bool = true
    ) {
        self.unplannedExpenseID = unplannedExpenseID
        self.allowedCardIDs = allowedCardIDs
        self.initialCardID = initialCardID
        self.initialDate = initialDate
        self.onSaved = onSaved
        self.includeNavigationContainer = includeNavigationContainer
    }

    // MARK: Body
    var body: some View {
        AddUnplannedExpenseView(
            unplannedExpenseID: unplannedExpenseID,
            allowedCardIDs: allowedCardIDs,
            initialCardID: initialCardID,
            initialDate: initialDate,
            onSaved: onSaved,
            includeNavigationContainer: includeNavigationContainer
        )
    }
}

// MARK: - Sidebar Convenience
extension AddVariableExpenseView {
    static func navigationDestination(
        unplannedExpenseID: NSManagedObjectID? = nil,
        allowedCardIDs: Set<NSManagedObjectID>? = nil,
        initialCardID: NSManagedObjectID? = nil,
        initialDate: Date? = nil,
        onSaved: @escaping () -> Void = {}
    ) -> some View {
        AddVariableExpenseView(
            unplannedExpenseID: unplannedExpenseID,
            allowedCardIDs: allowedCardIDs,
            initialCardID: initialCardID,
            initialDate: initialDate,
            onSaved: onSaved,
            includeNavigationContainer: false
        )
        .environment(\.managedObjectContext, CoreDataService.shared.viewContext)
    }
}
