import Foundation

@MainActor
final class BudgetsViewState: ObservableObject {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadExpandedValue(defaultValue: Bool, localKey: String, cloudKey: String, cloudEnabled: Bool) -> Bool {
        if cloudEnabled {
            let kv = NSUbiquitousKeyValueStore.default
            if kv.object(forKey: cloudKey) != nil {
                let value = kv.bool(forKey: cloudKey)
                defaults.set(value, forKey: localKey)
                return value
            }
            if defaults.object(forKey: localKey) != nil {
                let value = defaults.bool(forKey: localKey)
                kv.set(value, forKey: cloudKey)
                kv.synchronize()
                return value
            }
        }
        if defaults.object(forKey: localKey) != nil {
            return defaults.bool(forKey: localKey)
        }
        return defaultValue
    }

    func persistExpandedValue(_ value: Bool, localKey: String, cloudKey: String, cloudEnabled: Bool) {
        defaults.set(value, forKey: localKey)
        syncExpandedValueIfNeeded(value, cloudKey: cloudKey, cloudEnabled: cloudEnabled)
    }

    private func syncExpandedValueIfNeeded(_ value: Bool, cloudKey: String, cloudEnabled: Bool) {
        guard cloudEnabled else { return }
        let kv = NSUbiquitousKeyValueStore.default
        kv.set(value, forKey: cloudKey)
        kv.synchronize()
    }
}

