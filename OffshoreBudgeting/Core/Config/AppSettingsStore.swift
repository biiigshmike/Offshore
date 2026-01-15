import Foundation

// MARK: - AppSettingsStore
protocol AppSettingsStore {
    func bool(for key: AppSettingsKeys) -> Bool?
    func int(for key: AppSettingsKeys) -> Int?
    func string(for key: AppSettingsKeys) -> String?
    func double(for key: AppSettingsKeys) -> Double?

    func set(_ value: Bool, for key: AppSettingsKeys)
    func set(_ value: Int, for key: AppSettingsKeys)
    func set(_ value: String, for key: AppSettingsKeys)
    func set(_ value: Double, for key: AppSettingsKeys)
}

