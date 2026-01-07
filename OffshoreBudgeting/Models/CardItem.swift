//
//  CardItem.swift
//  SoFar
//
//  Single source of truth for the UI model used by Cards screens.
//  Centralizing this fixes "ambiguous for type lookup" and enables Equatable synthesis.
//
import Foundation
import CoreData

// MARK: - CardEffect
/// Surface treatment applied to a card (stored in Core Data).
enum CardEffect: String, CaseIterable, Identifiable, Codable {
    case plastic
    case metal
    case holographic

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .plastic: return "Plastic"
        case .metal: return "Metal"
        case .holographic: return "Holographic"
        }
    }

    static func fromStoredValue(_ raw: String?) -> CardEffect {
        guard let raw else { return .plastic }
        return CardEffect(rawValue: raw.lowercased()) ?? .plastic
    }
}

// MARK: - CardItem (UI Model)
/// Lightweight UI model for card tiles, lists, and pickers.
/// - Identity:
///   - Prefer Core Data `objectID` when present (stable across saves).
///   - Fallback to `uuid` (Card.id attribute in Core Data) when available.
///   - Otherwise use a preview-only stable string.
/// - Mutability:
///   - `name` and `theme` are `var` so rename/theme changes can be reflected in-place.
struct CardItem: Identifiable, Hashable {
    // MARK: Identity
    /// Stable Core Data identity when available. Nil for preview-only items.
    let objectID: NSManagedObjectID?
    /// Optional Core Data UUID attribute `id`.
    let uuid: UUID?

    // MARK: Display
    var name: String
    var theme: CardTheme
    var effect: CardEffect = .plastic
    /// Optional balance/total for display (e.g., aggregated spend in the period).
    var balance: Double? = nil

    // MARK: Identifiable
    var id: String {
        if let oid = objectID {
            return oid.uriRepresentation().absoluteString
        }
        if let uuid {
            return "uuid:\(uuid.uuidString)"
        }
        return "preview:\(name)"
    }
}
