import Foundation

enum UbiquitousFlags {
    private static let hasCloudDataKey = "hasCloudData"

    static func hasCloudData() -> Bool {
        NSUbiquitousKeyValueStore.default.bool(forKey: hasCloudDataKey)
    }

    static func setHasCloudDataTrue() {
        let kv = NSUbiquitousKeyValueStore.default
        if kv.bool(forKey: hasCloudDataKey) == true { return }
        kv.set(true, forKey: hasCloudDataKey)
        kv.synchronize()
    }

    static func clearHasCloudData() {
        let kv = NSUbiquitousKeyValueStore.default
        kv.set(false, forKey: hasCloudDataKey)
        kv.synchronize()
    }
}
