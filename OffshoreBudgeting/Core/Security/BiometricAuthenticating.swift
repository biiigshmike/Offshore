import Foundation
import LocalAuthentication

// MARK: - BiometricAuthResult
enum BiometricAuthResult: Equatable {
    case success
    case failure(BiometricError)
    case cancelled
}

// MARK: - BiometricAuthenticating
protocol BiometricAuthenticating {
    func supportedBiometryType() -> LABiometryType
    func canEvaluateDeviceOwnerAuthentication(errorOut: inout BiometricError?) -> Bool
    func authenticate(reason: String) async -> BiometricAuthResult
}

// MARK: - LocalAuthenticationBiometricAuthenticator
final class LocalAuthenticationBiometricAuthenticator: BiometricAuthenticating {
    private let manager: BiometricAuthenticationManager

    init(manager: BiometricAuthenticationManager = .shared) {
        self.manager = manager
    }

    func supportedBiometryType() -> LABiometryType {
        manager.supportedBiometryType()
    }

    func canEvaluateDeviceOwnerAuthentication(errorOut: inout BiometricError?) -> Bool {
        manager.canEvaluateDeviceOwnerAuthentication(errorOut: &errorOut)
    }

    func authenticate(reason: String) async -> BiometricAuthResult {
        await withCheckedContinuation { continuation in
            manager.authenticate(reason: reason, policy: .deviceOwnerAuthentication) { result in
                switch result {
                case .success:
                    continuation.resume(returning: .success)
                case .failure(let error):
                    if error == .cancelledByUser || error == .cancelledBySystem {
                        continuation.resume(returning: .cancelled)
                    } else {
                        continuation.resume(returning: .failure(error))
                    }
                }
            }
        }
    }
}

#if DEBUG
// MARK: - UITestBiometricAuthenticator
final class UITestBiometricAuthenticator: BiometricAuthenticating {
    private let result: BiometricAuthResult
    private let delay: TimeInterval
    private let biometryType: LABiometryType
    private let isAvailable: Bool

    init(result: BiometricAuthResult,
         delay: TimeInterval = 0.25,
         biometryType: LABiometryType = .faceID,
         isAvailable: Bool = true) {
        self.result = result
        self.delay = delay
        self.biometryType = biometryType
        self.isAvailable = isAvailable
    }

    func supportedBiometryType() -> LABiometryType {
        isAvailable ? biometryType : .none
    }

    func canEvaluateDeviceOwnerAuthentication(errorOut: inout BiometricError?) -> Bool {
        if isAvailable { return true }
        errorOut = .notAvailable
        return false
    }

    func authenticate(reason: String) async -> BiometricAuthResult {
        if delay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        return result
    }
}
#endif
