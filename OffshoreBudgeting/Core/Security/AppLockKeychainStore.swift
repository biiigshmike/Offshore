import Foundation
import Security
import LocalAuthentication

// MARK: - AppLockKeychainStoring
protocol AppLockKeychainStoring {
    func hasUnlockToken() -> Bool
    func storeUnlockToken() -> Bool
    func deleteUnlockToken()
}

// MARK: - KeychainAppLockStore
final class KeychainAppLockStore: AppLockKeychainStoring {
    private let service: String
    private let account = "app_lock_unlock_token"

    init(service: String? = nil) {
        let bundleID = Bundle.main.bundleIdentifier ?? "com.offshorebudgeting"
        self.service = service ?? "\(bundleID).applock"
    }

    func hasUnlockToken() -> Bool {
        var query = baseQuery()
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnData as String] = kCFBooleanFalse
        let context = LAContext()
        context.interactionNotAllowed = true
        query[kSecUseAuthenticationContext as String] = context

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        switch status {
        case errSecSuccess, errSecInteractionNotAllowed:
            return true
        default:
            return false
        }
    }

    func storeUnlockToken() -> Bool {
        deleteUnlockToken()
        guard let accessControl = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            [.userPresence],
            nil
        ) else {
            return false
        }

        let token = UUID().uuidString.data(using: .utf8) ?? Data()
        var query = baseQuery()
        query[kSecValueData as String] = token
        query[kSecAttrAccessControl as String] = accessControl

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    func deleteUnlockToken() {
        let query = baseQuery()
        SecItemDelete(query as CFDictionary)
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}

#if DEBUG
// MARK: - AppLockUserDefaultsStore (UI Tests)
final class AppLockUserDefaultsStore: AppLockKeychainStoring {
    private let key = "uitest_app_lock_token"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func hasUnlockToken() -> Bool {
        defaults.bool(forKey: key)
    }

    func storeUnlockToken() -> Bool {
        defaults.set(true, forKey: key)
        defaults.synchronize()
        return true
    }

    func deleteUnlockToken() {
        defaults.removeObject(forKey: key)
        defaults.synchronize()
    }
}
#endif
