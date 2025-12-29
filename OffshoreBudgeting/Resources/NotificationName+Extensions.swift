//
//  NotificationName+Extensions.swift
//  SoFar
//
//  Created by Michael Brown on 8/11/25.
//

import Foundation

// MARK: - App Notification Names
/// Centralized notification names to avoid stringly-typed mistakes.
/// Add new custom Notification.Name constants here as your app grows.
extension Notification.Name {

    // MARK: - dataStoreDidChange
    /// Posted by the app whenever Core Data changes are persisted. Views or
    /// view models can observe this to trigger refreshes.
    ///
    /// Usage:
    /// NotificationCenter.default.post(name: .dataStoreDidChange, object: nil)
    /// NotificationCenter.default.addObserver(forName: .dataStoreDidChange, object: nil, queue: .main) { _ in ... }
    static let dataStoreDidChange = Notification.Name("dataStoreDidChange")
    static let homeViewInitialDataLoaded = Notification.Name("homeViewInitialDataLoaded")
    static let workspaceDidChange = Notification.Name("workspaceDidChange")
    
    // Intentionally lean: add new app-wide notifications only when used.
}
