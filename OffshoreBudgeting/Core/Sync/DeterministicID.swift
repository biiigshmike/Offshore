import CryptoKit
import Foundation

// MARK: - DeterministicID
/// Deterministic UUID generation used to prevent cross-device duplicates when Cloud sync merges datasets.
///
/// Design:
/// - Uses UUID v5 style (SHA-1) hashing with a fixed namespace.
/// - Identity keys are normalized and stable across devices.
enum DeterministicID {
    // MARK: Namespace
    /// Fixed namespace UUID for Offshore Budgeting deterministic IDs.
    ///
    /// - Important: Do not change once shipped, or IDs will change across versions.
    static let namespace: UUID = UUID(uuidString: "1F0B11C1-1A1D-4A0B-AE7A-36A0D9B07E8C")!

    // MARK: Public API
    static func cardID(workspaceID: UUID, name: String) -> UUID {
        uuidV5(name: "card|\(workspaceID.uuidString)|name=\(normalizeName(name))")
    }

    static func categoryID(workspaceID: UUID, name: String) -> UUID {
        uuidV5(name: "category|\(workspaceID.uuidString)|name=\(normalizeName(name))")
    }

    static func budgetID(workspaceID: UUID, startDate: Date, endDate: Date) -> UUID {
        let start = canonicalDayKey(startDate)
        let end = canonicalDayKey(endDate)
        return uuidV5(name: "budget|\(workspaceID.uuidString)|start=\(start)|end=\(end)")
    }

    static func presetTemplateID(
        workspaceID: UUID,
        title: String,
        plannedAmount: Double,
        categoryID: UUID?,
        cardID: UUID?
    ) -> UUID {
        let t = normalizeName(title)
        let amt = canonicalMoneyKey(plannedAmount)
        let cat = categoryID?.uuidString ?? "nil"
        let card = cardID?.uuidString ?? "nil"
        return uuidV5(name: "preset|\(workspaceID.uuidString)|title=\(t)|planned=\(amt)|category=\(cat)|card=\(card)")
    }

    // MARK: Normalization
    static func normalizeName(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "" }
        let folded = trimmed.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        let parts = folded
            .split(whereSeparator: { $0.isWhitespace || $0.isNewline })
            .map(String.init)
            .filter { !$0.isEmpty }
        return parts.joined(separator: " ").lowercased()
    }

    static func canonicalMoneyKey(_ value: Double) -> String {
        let rounded = (value * 100.0).rounded() / 100.0
        return String(format: "%.2f", rounded)
    }

    static func canonicalDayKey(_ date: Date) -> String {
        let day = Calendar.current.startOfDay(for: date)
        // Use an ISO-8601 day stamp to avoid locale/timezone drift.
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        let comps = cal.dateComponents([.year, .month, .day], from: day)
        let y = comps.year ?? 0
        let m = comps.month ?? 0
        let d = comps.day ?? 0
        return String(format: "%04d-%02d-%02d", y, m, d)
    }

    // MARK: UUID v5
    static func uuidV5(name: String) -> UUID {
        uuidV5(namespace: namespace, name: name)
    }

    static func uuidV5(namespace: UUID, name: String) -> UUID {
        var namespaceBytes = [UInt8](repeating: 0, count: 16)
        withUnsafeBytes(of: namespace.uuid) { bytes in
            namespaceBytes = Array(bytes)
        }

        let nameBytes = Array(name.utf8)
        let data = Data(namespaceBytes + nameBytes)
        let digest = Insecure.SHA1.hash(data: data)
        var hashBytes = Array(digest)

        // UUID v5: set version (5) and variant (RFC 4122)
        hashBytes[6] = (hashBytes[6] & 0x0F) | 0x50
        hashBytes[8] = (hashBytes[8] & 0x3F) | 0x80

        let uuidBytes = (
            hashBytes[0], hashBytes[1], hashBytes[2], hashBytes[3],
            hashBytes[4], hashBytes[5], hashBytes[6], hashBytes[7],
            hashBytes[8], hashBytes[9], hashBytes[10], hashBytes[11],
            hashBytes[12], hashBytes[13], hashBytes[14], hashBytes[15]
        )
        return UUID(uuid: uuidBytes)
    }
}

