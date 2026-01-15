import Foundation

// MARK: - UserDefaultsAppSettingsStore
struct UserDefaultsAppSettingsStore: AppSettingsStore {
    let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func bool(for key: AppSettingsKeys) -> Bool? {
        guard let object = defaults.object(forKey: key.rawValue) else { return nil }
        if let value = object as? Bool { return value }
        if let value = object as? NSNumber { return value.boolValue }
        return nil
    }

    func int(for key: AppSettingsKeys) -> Int? {
        guard let object = defaults.object(forKey: key.rawValue) else { return nil }
        if let value = object as? Int { return value }
        if let value = object as? NSNumber { return value.intValue }
        return nil
    }

    func string(for key: AppSettingsKeys) -> String? {
        defaults.string(forKey: key.rawValue)
    }

    func double(for key: AppSettingsKeys) -> Double? {
        guard let object = defaults.object(forKey: key.rawValue) else { return nil }
        if let value = object as? Double { return value }
        if let value = object as? NSNumber { return value.doubleValue }
        if let value = object as? Date { return value.timeIntervalSince1970 }
        return nil
    }

    func set(_ value: Bool, for key: AppSettingsKeys) {
        defaults.set(value, forKey: key.rawValue)
    }

    func set(_ value: Int, for key: AppSettingsKeys) {
        defaults.set(value, forKey: key.rawValue)
    }

    func set(_ value: String, for key: AppSettingsKeys) {
        defaults.set(value, forKey: key.rawValue)
    }

    func set(_ value: Double, for key: AppSettingsKeys) {
        defaults.set(value, forKey: key.rawValue)
    }
}
