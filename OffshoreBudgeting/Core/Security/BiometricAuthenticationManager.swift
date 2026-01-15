//
//  BiometricAuthenticationManager.swift
//  OffshoreBudgeting
//
//  Created by Michael Brown on 2025-10-31.
//  Description: A small service that wraps LocalAuthentication to request Face ID / Touch ID
//  across iOS, iPadOS, and macOS. Use this to check availability and to trigger authentication.
//

import Foundation
import LocalAuthentication

// MARK: - BiometricError
/// Describes common, user-facing errors for biometric authentication.
public enum BiometricError: LocalizedError, Equatable {
    case notAvailable
    case notEnrolled
    case passcodeNotSet
    case lockedOut
    case cancelledByUser
    case cancelledBySystem
    case fallbackToPasscodeNotAllowed
    case authenticationFailed
    case unknown(NSError)

    public var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Biometrics are not available on this device."
        case .notEnrolled:
            return "No Face ID/Touch ID is enrolled."
        case .passcodeNotSet:
            return "A device passcode is required to enable app lock."
        case .lockedOut:
            return "Biometrics are locked out. Try your device passcode."
        case .cancelledByUser:
            return "You cancelled the authentication."
        case .cancelledBySystem:
            return "Authentication was cancelled by the system."
        case .fallbackToPasscodeNotAllowed:
            return "Passcode fallback is disabled for this request."
        case .authenticationFailed:
            return "Failed to verify your identity."
        case .unknown(let nsError):
            return nsError.localizedDescription
        }
    }
}

// MARK: - BiometricAuthenticationManager
/// A thin, testable wrapper for LocalAuthentication.
/// - Use `canEvaluateBiometrics()` to check availability/enrollment.
/// - Use `authenticate(...)` to prompt the user.
/// - Creates a fresh LAContext per request, per Apple's best practices.
public final class BiometricAuthenticationManager {

    // MARK: Singleton
    /// Use shared for convenience, or init your own for tests/DI.
    public static let shared = BiometricAuthenticationManager()

    // MARK: Initialization
    public init() {}

    // MARK: Public API
    /// Returns the biometry type supported on the device after evaluation.
    /// Call this after `canEvaluateBiometrics()` or inside completion of `authenticate`.
    public func supportedBiometryType() -> LABiometryType {
        let context = LAContext()
        _ = try? evaluateCanUseBiometrics(context: context)
        return context.biometryType
    }

    /// Checks if biometrics can be evaluated (hardware present + enrolled + not blocked).
    /// - Returns: `true` if available, otherwise `false`. If false, the `errorOut` is set.
    @discardableResult
    public func canEvaluateBiometrics(errorOut: inout BiometricError?) -> Bool {
        let context = LAContext()
        do {
            _ = try evaluateCanUseBiometrics(context: context)
            return true
        } catch let err as BiometricError {
            errorOut = err
            return false
        } catch let ns as NSError {
            errorOut = mapLAError(ns)
            return false
        }
    }

    /// Checks if device-owner authentication (biometrics or passcode) can be evaluated.
    /// - Returns: `true` if available, otherwise `false`. If false, the `errorOut` is set.
    @discardableResult
    public func canEvaluateDeviceOwnerAuthentication(errorOut: inout BiometricError?) -> Bool {
        let context = LAContext()
        do {
            _ = try evaluateCanUse(policy: .deviceOwnerAuthentication, context: context)
            return true
        } catch let err as BiometricError {
            errorOut = err
            return false
        } catch let ns as NSError {
            errorOut = mapLAError(ns)
            return false
        }
    }

    /// Prompts the user for biometrics (and optionally allows device passcode fallback).
    /// - Parameters:
    ///   - reason: Shown in the system prompt. Explain why you need auth.
    ///   - allowDevicePasscode: If true, uses `.deviceOwnerAuthentication`, otherwise `.deviceOwnerAuthenticationWithBiometrics`.
    ///   - completion: Called on the main thread with success or a `BiometricError`.
    public func authenticate(
        reason: String,
        allowDevicePasscode: Bool,
        completion: @escaping (Result<Void, BiometricError>) -> Void
    ) {
        let policy: LAPolicy = allowDevicePasscode ? .deviceOwnerAuthentication : .deviceOwnerAuthenticationWithBiometrics
        authenticate(reason: reason, policy: policy, completion: completion)
    }

    /// Prompts the user for authentication using the specified policy.
    public func authenticate(
        reason: String,
        policy: LAPolicy,
        completion: @escaping (Result<Void, BiometricError>) -> Void
    ) {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"

        // Pre-flight check
        do {
            try evaluateCanUse(policy: policy, context: context)
        } catch let err as BiometricError {
            DispatchQueue.main.async { completion(.failure(err)) }
            return
        } catch let ns as NSError {
            DispatchQueue.main.async { completion(.failure(self.mapLAError(ns))) }
            return
        }

        // Evaluate
        context.evaluatePolicy(policy, localizedReason: reason) { success, error in
            DispatchQueue.main.async {
                if success {
                    completion(.success(()))
                } else if let ns = error as NSError? {
                    completion(.failure(self.mapLAError(ns)))
                } else {
                    completion(.failure(.authenticationFailed))
                }
            }
        }
    }

    // MARK: Private Helpers
    /// Ensure biometrics exist and are usable.
    @discardableResult
    private func evaluateCanUseBiometrics(context: LAContext) throws -> Bool {
        var laError: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &laError) {
            return true
        }
        if let laError { throw mapLAError(laError) }
        throw BiometricError.notAvailable
    }

    /// Ensure policy is evaluatable, considering passcode fallback preference.
    @discardableResult
    private func evaluateCanUse(policy: LAPolicy, context: LAContext) throws -> Bool {
        var laError: NSError?
        if context.canEvaluatePolicy(policy, error: &laError) {
            return true
        }
        if let laError { throw mapLAError(laError) }
        throw BiometricError.notAvailable
    }

    /// Map LAError to our BiometricError.
    private func mapLAError(_ nsError: NSError) -> BiometricError {
        guard nsError.domain == LAError.errorDomain, let code = LAError.Code(rawValue: nsError.code) else {
            return .unknown(nsError)
        }
        switch code {
        case .biometryNotAvailable, .passcodeNotSet:
            return code == .passcodeNotSet ? .passcodeNotSet : .notAvailable
        case .biometryNotEnrolled:
            return .notEnrolled
        case .biometryLockout:
            return .lockedOut
        case .userCancel:
            return .cancelledByUser
        case .systemCancel, .appCancel:
            return .cancelledBySystem
        case .userFallback:
            return .fallbackToPasscodeNotAllowed
        case .authenticationFailed:
            return .authenticationFailed
        default:
            return .unknown(nsError)
        }
    }
}
