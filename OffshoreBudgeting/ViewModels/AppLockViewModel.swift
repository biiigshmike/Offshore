//
//  AppLockViewModel.swift
//  OffshoreBudgeting
//
//  Created by Michael Brown on 2025-10-31.
//  Description: ViewModel handling App Lock state and biometric prompts across platforms.
//  Updates (2025-10-31): Debounce/guard to avoid double prompts; lifecycle no longer auto-prompts,
//  App.swift now decides when to prompt.
//

import Foundation
import Combine
import LocalAuthentication

#if canImport(SwiftUI)
import SwiftUI
#endif
// AppKit is only available on native macOS apps, not Mac Catalyst
#if os(macOS) && !targetEnvironment(macCatalyst)
import AppKit
#endif

// MARK: - AppLockViewModel
/// Controls whether the UI is locked behind Face ID / Touch ID.
/// - Use `isLockEnabled` to gate behavior via user settings.
/// - Call `lock()` when app enters background or on cold start.
/// - Call `attemptUnlockWithDeviceAuth()` from App.swift (cold start / foreground).
@MainActor
public final class AppLockViewModel: ObservableObject {

    // MARK: Published State
    @Published public private(set) var isLocked: Bool = false
    @Published public private(set) var lastErrorMessage: String? = nil
    @Published public private(set) var isAuthenticating: Bool = false
    @Published public private(set) var isToggleInFlight: Bool = false
    @Published public private(set) var isDeviceAuthAvailable: Bool = true
    @Published public private(set) var availabilityMessage: String? = nil

    // MARK: User Setting
    /// Published mirror for UI bindings.
    @Published public private(set) var isLockEnabledPublished: Bool = false
    public var isLockEnabled: Bool { isLockEnabledPublished }

    // MARK: Dependencies
    private let appLockState: AppLockState
    private var authenticator: BiometricAuthenticating
    private var keychainStore: AppLockKeychainStoring
    private var uiTestDeviceAuthAvailableOverride: Bool? = nil
    private var uiTestAuthResultOverride: BiometricAuthResult? = nil
    private var cancellables: Set<AnyCancellable> = []

    // MARK: Internal Guards (debounce & reentrancy)
    private var lastPromptAt: Date? = nil
    private let promptThrottleSeconds: TimeInterval = 1.0
    private var unlockGraceUntil: Date? = nil
    private let unlockGraceSeconds: TimeInterval = 0.8

    // MARK: Initialization
    init(appLockState: AppLockState,
         authenticator: BiometricAuthenticating = LocalAuthenticationBiometricAuthenticator(),
         keychainStore: AppLockKeychainStoring = KeychainAppLockStore()) {
        self.appLockState = appLockState
        self.authenticator = authenticator
        self.keychainStore = keychainStore
#if DEBUG
        configureForUITestingIfNeeded()
#endif
        isLockEnabledPublished = appLockState.isEnabled
        observeLockEnabledSetting()
        observeLifecycle()
    }

    // MARK: Public Controls
    /// Manually lock the UI (e.g., on cold start or when app resigns active).
    public func lock() {
        guard shouldRequireAuthentication else { return }
        var deviceAuthError: BiometricError?
        guard authenticator.canEvaluateDeviceOwnerAuthentication(errorOut: &deviceAuthError) else {
            disableLockForUnavailableAuth(deviceAuthError)
            return
        }
        isAuthenticating = false
        isLocked = true
    }

    /// Attempts to unlock via device-owner authentication (biometrics or device passcode).
    /// Safe to call repeatedly; internal debounce prevents double prompts.
    /// - Parameter reason: Message for system prompt.
    public func attemptUnlockWithDeviceAuth(reason: String = "Unlock Offshore Budgeting") {
#if DEBUG
        configureForUITestingIfNeeded()
#endif
        guard shouldRequireAuthentication else {
            isLocked = false
            return
        }
        // Debounce / guard concurrent prompts
        if isAuthenticating { return }
        if let last = lastPromptAt, Date().timeIntervalSince(last) < promptThrottleSeconds {
            return
        }

#if DEBUG
        if let uiTestResult = uiTestAuthResultOverride {
            let available = uiTestDeviceAuthAvailableOverride ?? true
            guard available else {
                disableLockForUnavailableAuth(.passcodeNotSet)
                return
            }
            isAuthenticating = true
            lastPromptAt = Date()
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isAuthenticating = false
                switch uiTestResult {
                case .success:
                    self.lastErrorMessage = nil
                    self.unlockGraceUntil = Date().addingTimeInterval(self.unlockGraceSeconds)
                    #if canImport(SwiftUI)
                    withAnimation(.easeInOut(duration: 0.2)) {
                        self.isLocked = false
                    }
                    #else
                    self.isLocked = false
                    #endif
                case .cancelled:
                    self.lastErrorMessage = BiometricError.cancelledByUser.localizedDescription
                case .failure(let error):
                    self.lastErrorMessage = error.localizedDescription
                }
            }
            return
        }
#endif

        var deviceAuthError: BiometricError?
        guard authenticator.canEvaluateDeviceOwnerAuthentication(errorOut: &deviceAuthError) else {
            disableLockForUnavailableAuth(deviceAuthError)
            return
        }

        isAuthenticating = true
        lastPromptAt = Date()

        Task { @MainActor [weak self] in
            guard let self else { return }
            let result = await authenticator.authenticate(reason: reason)
            self.isAuthenticating = false
            switch result {
            case .success:
                self.lastErrorMessage = nil
                self.unlockGraceUntil = Date().addingTimeInterval(self.unlockGraceSeconds)
                #if canImport(SwiftUI)
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.isLocked = false
                }
                #else
                self.isLocked = false
                #endif
            case .cancelled:
                self.lastErrorMessage = BiometricError.cancelledByUser.localizedDescription
            case .failure(let error):
                self.lastErrorMessage = error.localizedDescription
                // Remain locked; user can tap again or we can re-prompt on demand later.
            }
        }
    }

    // MARK: Presentation Helpers
    public var lockSubtitle: String {
        canUseBiometricsNow ? "Use \(biometricLabel)" : "Use device passcode"
    }

    public var lockIconName: String {
        guard canUseBiometricsNow else { return "lock.fill" }
        switch authenticator.supportedBiometryType() {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        default: return "lock.fill"
        }
    }

    public var shouldRequireAuthentication: Bool {
        guard isLockEnabled else { return false }
        guard keychainStore.hasUnlockToken() else {
            setLockEnabled(false)
            isLocked = false
            return false
        }
        return true
    }

    public func setAppLockEnabled(_ enabled: Bool) async {
#if DEBUG
        configureForUITestingIfNeeded()
#endif
        if enabled {
            await enableLock()
        } else {
            disableLock()
        }
    }

    public func refreshAvailability() {
#if DEBUG
        configureForUITestingIfNeeded()
        if let overrides = uiTestOverridesFromEnvironment() {
            isDeviceAuthAvailable = overrides.available
            if overrides.available {
                availabilityMessage = nil
            } else {
                availabilityMessage = "A device passcode is required to enable app lock."
                setLockEnabled(false)
                isLocked = false
            }
            return
        }
#endif
        if let override = uiTestDeviceAuthAvailableOverride {
            isDeviceAuthAvailable = override
            if override {
                availabilityMessage = nil
            } else {
                availabilityMessage = "A device passcode is required to enable app lock."
                setLockEnabled(false)
                isLocked = false
            }
            return
        }
        var authError: BiometricError?
        let available = authenticator.canEvaluateDeviceOwnerAuthentication(errorOut: &authError)
        isDeviceAuthAvailable = available
        if available {
            availabilityMessage = nil
        } else {
            availabilityMessage = authError?.localizedDescription ?? "A device passcode is required to enable app lock."
            setLockEnabled(false)
            isLocked = false
        }
    }

    public func disableAppLockForUITests() {
        setLockEnabled(false)
        isLocked = false
        keychainStore.deleteUnlockToken()
    }

    func configureForUITesting(flags: UITestingFlags) {
        #if DEBUG
        guard flags.isUITesting, flags.allowAppLock else { return }
        let result: BiometricAuthResult
        switch flags.biometricAuthResult {
        case .success:
            result = .success
        case .failure:
            result = .failure(.authenticationFailed)
        case .cancel:
            result = .cancelled
        case .none:
            result = .success
        }
        let isAvailable = flags.deviceAuthAvailableOverride ?? true
        uiTestDeviceAuthAvailableOverride = isAvailable
        uiTestAuthResultOverride = result
        authenticator = UITestBiometricAuthenticator(result: result, isAvailable: isAvailable)
        keychainStore = AppLockUserDefaultsStore()
        isDeviceAuthAvailable = isAvailable
        availabilityMessage = isAvailable ? nil : "A device passcode is required to enable app lock."
        #endif
    }

    #if DEBUG
    @discardableResult
    private func configureForUITestingIfNeeded() -> Bool {
        guard let overrides = uiTestOverridesFromEnvironment() else { return false }
        uiTestDeviceAuthAvailableOverride = overrides.available
        uiTestAuthResultOverride = overrides.result
        authenticator = UITestBiometricAuthenticator(result: overrides.result, isAvailable: overrides.available)
        keychainStore = AppLockUserDefaultsStore()
        isDeviceAuthAvailable = overrides.available
        availabilityMessage = overrides.available ? nil : "A device passcode is required to enable app lock."
        return true
    }

    private func uiTestOverridesFromEnvironment() -> (available: Bool, result: BiometricAuthResult)? {
        let processInfo = ProcessInfo.processInfo
        guard processInfo.arguments.contains("-ui-testing") else { return nil }
        let env = processInfo.environment
        guard env["UITEST_ALLOW_APP_LOCK"] == "1" else { return nil }
        let available: Bool = {
            guard let raw = env["UITEST_DEVICE_AUTH_AVAILABLE"] else { return true }
            switch raw.lowercased() {
            case "1", "true", "yes": return true
            case "0", "false", "no": return false
            default: return true
            }
        }()
        let deviceAuthRaw = env["UITEST_DEVICE_AUTH_RESULT"] ?? env["UITEST_BIOMETRIC_RESULT"]
        let uiResult = deviceAuthRaw
            .flatMap { UITestBiometricAuthResult(rawValue: $0.lowercased()) }
        let result: BiometricAuthResult
        switch uiResult {
        case .success:
            result = .success
        case .failure:
            result = .failure(.authenticationFailed)
        case .cancel:
            result = .cancelled
        case .none:
            result = .success
        }
        return (available: available, result: result)
    }
    #endif

    // MARK: Private: App Lifecycle Observing
    /// We **only** lock on background here. We no longer auto-prompt on foreground.
    /// App.swift decides when to prompt (cold start, foreground, etc.).
    private func observeLifecycle() {
        #if os(macOS) && !targetEnvironment(macCatalyst)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidResignActive),
            name: NSApplication.didResignActiveNotification,
            object: nil
        )
        // Removed willBecomeActive auto-prompt to avoid double sheets.
        #endif
    }

    private var biometricLabel: String {
        switch authenticator.supportedBiometryType() {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        default: return "Biometrics"
        }
    }

    private var canUseBiometricsNow: Bool {
        authenticator.supportedBiometryType() != .none
    }

    private func setLockEnabled(_ value: Bool) {
        appLockState.isEnabled = value
        isLockEnabledPublished = value
    }

    private func observeLockEnabledSetting() {
        appLockState.$isEnabled
            .removeDuplicates()
            .sink { [weak self] newValue in
                guard let self else { return }
                self.isLockEnabledPublished = newValue
            }
            .store(in: &cancellables)
    }

    private func disableLockForUnavailableAuth(_ error: BiometricError?) {
        lastErrorMessage = error?.localizedDescription ?? "Device authentication unavailable."
        availabilityMessage = lastErrorMessage
        setLockEnabled(false)
        isLocked = false
    }

    private func enableLock() async {
        if isToggleInFlight { return }
#if DEBUG
        _ = configureForUITestingIfNeeded()
        if let uiTestResult = uiTestAuthResultOverride {
            let available = uiTestDeviceAuthAvailableOverride ?? true
            guard available else {
                availabilityMessage = "A device passcode is required to enable app lock."
                setLockEnabled(false)
                isDeviceAuthAvailable = false
                return
            }
            isToggleInFlight = true
            let result = uiTestResult
            isToggleInFlight = false
            switch result {
            case .success:
                if keychainStore.storeUnlockToken() {
                    setLockEnabled(true)
                    lastErrorMessage = nil
                    availabilityMessage = nil
                } else {
                    setLockEnabled(false)
                    lastErrorMessage = "Unable to enable App Lock. Please try again."
                    availabilityMessage = lastErrorMessage
                }
            case .cancelled:
                setLockEnabled(false)
                lastErrorMessage = BiometricError.cancelledByUser.localizedDescription
                availabilityMessage = lastErrorMessage
            case .failure(let error):
                setLockEnabled(false)
                lastErrorMessage = error.localizedDescription
                availabilityMessage = lastErrorMessage
            }
            return
        }
        if let testAuthenticator = authenticator as? UITestBiometricAuthenticator {
            var authError: BiometricError?
            let available = testAuthenticator.canEvaluateDeviceOwnerAuthentication(errorOut: &authError)
            guard available else {
                availabilityMessage = authError?.localizedDescription ?? "A device passcode is required to enable app lock."
                setLockEnabled(false)
                isDeviceAuthAvailable = false
                return
            }
            isToggleInFlight = true
            let result = await testAuthenticator.authenticate(reason: "Use App Lock")
            isToggleInFlight = false
            switch result {
            case .success:
                if keychainStore.storeUnlockToken() {
                    setLockEnabled(true)
                    lastErrorMessage = nil
                    availabilityMessage = nil
                } else {
                    setLockEnabled(false)
                    lastErrorMessage = "Unable to enable App Lock. Please try again."
                    availabilityMessage = lastErrorMessage
                }
            case .cancelled:
                setLockEnabled(false)
                lastErrorMessage = BiometricError.cancelledByUser.localizedDescription
                availabilityMessage = lastErrorMessage
            case .failure(let error):
                setLockEnabled(false)
                lastErrorMessage = error.localizedDescription
                availabilityMessage = lastErrorMessage
            }
            return
        }
#endif
        var authError: BiometricError?
        let available = authenticator.canEvaluateDeviceOwnerAuthentication(errorOut: &authError)
        guard available else {
            availabilityMessage = authError?.localizedDescription ?? "A device passcode is required to enable app lock."
            setLockEnabled(false)
            return
        }

        isToggleInFlight = true
        let result = await authenticator.authenticate(reason: "Use App Lock")
        isToggleInFlight = false

        switch result {
        case .success:
            if keychainStore.storeUnlockToken() {
                setLockEnabled(true)
                lastErrorMessage = nil
                availabilityMessage = nil
            } else {
                setLockEnabled(false)
                lastErrorMessage = "Unable to enable App Lock. Please try again."
                availabilityMessage = lastErrorMessage
            }
        case .cancelled:
            setLockEnabled(false)
            lastErrorMessage = BiometricError.cancelledByUser.localizedDescription
            availabilityMessage = lastErrorMessage
        case .failure(let error):
            setLockEnabled(false)
            lastErrorMessage = error.localizedDescription
            availabilityMessage = lastErrorMessage
        }
    }

    private func disableLock() {
        keychainStore.deleteUnlockToken()
        setLockEnabled(false)
        isLocked = false
        lastErrorMessage = nil
    }

    // MARK: Lifecycle Selectors (UIKit)
    // UIKit locking is managed by the App via scenePhase (.background)

    // MARK: Lifecycle Selectors (AppKit)
    #if os(macOS) && !targetEnvironment(macCatalyst)
    @objc private func appDidResignActive() {
        if isAuthenticating { return }
        if let until = unlockGraceUntil, Date() < until { return }
        lock()
    }
    #endif
}
