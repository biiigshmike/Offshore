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
/// - Call `attemptUnlockWithBiometrics()` from App.swift (cold start / foreground).
@MainActor
public final class AppLockViewModel: ObservableObject {

    // MARK: Published State
    @Published public private(set) var isLocked: Bool = false
    @Published public private(set) var lastErrorMessage: String? = nil
    @Published public private(set) var isAuthenticating: Bool = false

    // MARK: User Setting
    /// Persisted user preference for enabling the lock.
    /// Toggle this in your Settings screen.
    @AppStorage("appLockEnabled") public var isLockEnabled: Bool = true

    // MARK: Dependencies
    private let biometricManager: BiometricAuthenticationManager

    // MARK: Internal Guards (debounce & reentrancy)
    private var lastPromptAt: Date? = nil
    private let promptThrottleSeconds: TimeInterval = 1.0
    private var unlockGraceUntil: Date? = nil
    private let unlockGraceSeconds: TimeInterval = 0.8

    // MARK: Initialization
    public init(biometricManager: BiometricAuthenticationManager = .shared) {
        self.biometricManager = biometricManager
        observeLifecycle()
    }

    // MARK: Public Controls
    /// Manually lock the UI (e.g., on cold start or when app resigns active).
    public func lock() {
        guard isLockEnabled else { return }
        var deviceAuthError: BiometricError?
        guard biometricManager.canEvaluateDeviceOwnerAuthentication(errorOut: &deviceAuthError) else {
            disableLockForUnavailableAuth(deviceAuthError)
            return
        }
        isAuthenticating = false
        isLocked = true
    }

    /// Attempts to unlock via device-owner authentication (biometrics or device passcode).
    /// Safe to call repeatedly; internal debounce prevents double prompts.
    /// - Parameter reason: Message for system prompt.
    public func attemptUnlockWithBiometrics(reason: String = "Unlock Offshore Budgeting") {
        guard isLockEnabled else {
            isLocked = false
            return
        }
        if !isLocked {
            isLocked = true
        }
        // Debounce / guard concurrent prompts
        if isAuthenticating { return }
        if let last = lastPromptAt, Date().timeIntervalSince(last) < promptThrottleSeconds {
            return
        }

        var deviceAuthError: BiometricError?
        guard biometricManager.canEvaluateDeviceOwnerAuthentication(errorOut: &deviceAuthError) else {
            disableLockForUnavailableAuth(deviceAuthError)
            return
        }

        let policy = preferredPolicy()
        isAuthenticating = true
        lastPromptAt = Date()

        biometricManager.authenticate(reason: reason, policy: policy) { [weak self] result in
            guard let self else { return }
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
        switch biometricManager.supportedBiometryType() {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        default: return "lock.fill"
        }
    }

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
        switch biometricManager.supportedBiometryType() {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        default: return "Biometrics"
        }
    }

    private var canUseBiometricsNow: Bool {
        var biometricError: BiometricError?
        return biometricManager.canEvaluateBiometrics(errorOut: &biometricError)
    }

    private func preferredPolicy() -> LAPolicy {
        return .deviceOwnerAuthentication
    }

    private func disableLockForUnavailableAuth(_ error: BiometricError?) {
        lastErrorMessage = error?.localizedDescription ?? "Device authentication unavailable."
        isLockEnabled = false
        isLocked = false
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
