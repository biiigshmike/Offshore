//
//  CardItem+CoreDataBridge.swift
//  SoFar
//
//  Bridges Core Data `Card` objects to your UI model `CardItem` so we
//  can reuse CardTileView anywhere in the app (including pickers).
//
//  Usage:
//    let uiItem = CardItem(from: card) // card: CoreData `Card`
//

import Foundation
import CoreData
import SwiftUI

// MARK: - CardItem + Core Data Bridge
extension CardItem {

    // MARK: init(from:appearanceStore:)
    /// Creates a `CardItem` from a Core Data `Card` object.
    /// - Parameters:
    ///   - managedCard: The Core Data card object to bridge.
    /// - Discussion:
    ///   Uses the per-card theme and effect persisted on the `Card` managed object. If missing,
    ///   falls back to `.graphite` and `.plastic` to guarantee a valid UI.
    @MainActor
    init(from managedCard: Card) {

        // Pull UUID + name safely from Core Data.
        let cardUUID: UUID = managedCard.value(forKey: "id") as? UUID ?? UUID()
        let cardName: String = managedCard.value(forKey: "name") as? String ?? "Untitled"

        // Resolve persisted theme from Core Data first; fallback to legacy store.
        let theme: CardTheme = {
            if managedCard.entity.attributesByName["theme"] != nil,
               let raw = managedCard.value(forKey: "theme") as? String,
               let t = CardTheme(rawValue: raw) {
                return t
            }
            return .graphite
        }()

        let effect: CardEffect = {
            guard managedCard.entity.attributesByName["effect"] != nil else { return .plastic }
            let raw = managedCard.value(forKey: "effect") as? String
            return CardEffect.fromStoredValue(raw)
        }()

        // Use the memberwise initializer of `CardItem`.
        self.init(
            objectID: managedCard.objectID,
            uuid: cardUUID,
            name: cardName,
            theme: theme,
            effect: effect,
            balance: nil
        )
    }
}
