//
//  SheetDetentsCompat.swift
//  SoFar
//
//  Minimal compatibility shim to apply presentation detents on iOS 16+
//  while keeping a neutral type for earlier OS versions.
//

import SwiftUI

// MARK: - UBPresentationDetent (compat wrapper)
enum UBPresentationDetent: Equatable, Hashable {
    case medium
    case large
    case fraction(Double)

    @available(iOS 16.0, macCatalyst 16.0, *)
    var systemDetent: PresentationDetent {
        switch self {
        case .medium: return .medium
        case .large: return .large
        case .fraction(let v): return .fraction(v)
        }
    }
}

// MARK: - Detents application helper
extension View {
    /// Applies presentationDetents and drag indicator only on iOS 16+.
    /// - Parameters:
    ///   - detents: Compat detents to apply.
    ///   - selection: Optional selection binding (ignored on older OSes).
    func applyDetentsIfAvailable(
        detents: [UBPresentationDetent],
        selection: Binding<UBPresentationDetent>?
    ) -> some View {
        if #available(iOS 16.0, macCatalyst 16.0, *) {
            let systemDetents = Set(detents.map { $0.systemDetent })
            if let selection {
                let bridged = Binding<PresentationDetent>(
                    get: { selection.wrappedValue.systemDetent },
                    set: { newValue in
                        let mapped: UBPresentationDetent
                        switch newValue {
                        case .medium: mapped = .medium
                        case .large: mapped = .large
                        default: mapped = .medium
                        }
                        selection.wrappedValue = mapped
                    }
                )
                return AnyView(
                    self
                        .presentationDetents(systemDetents, selection: bridged)
                        .presentationDragIndicator(.visible)
                )
            } else {
                return AnyView(
                    self
                        .presentationDetents(systemDetents)
                        .presentationDragIndicator(.visible)
                )
            }
        } else {
            return AnyView(self)
        }
    }
}

