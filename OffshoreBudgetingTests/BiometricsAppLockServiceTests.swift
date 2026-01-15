import XCTest
import LocalAuthentication
@testable import Offshore

@MainActor
final class BiometricsAppLockServiceTests: XCTestCase {
    private let appLockKey = "appLockEnabled"
    private var originalValue: Any?

    override func setUpWithError() throws {
        try super.setUpWithError()
        originalValue = UserDefaults.standard.object(forKey: appLockKey)
        UserDefaults.standard.set(false, forKey: appLockKey)
    }

    override func tearDownWithError() throws {
        if let originalValue {
            UserDefaults.standard.set(originalValue, forKey: appLockKey)
        } else {
            UserDefaults.standard.removeObject(forKey: appLockKey)
        }
        try super.tearDownWithError()
    }

	    func testEnableSuccessSetsToggleAndKeychainMarker() async {
	        let keychain = InMemoryAppLockStore()
	        let authenticator = TestBiometricAuthenticator(result: .success)
	        let appLockState = AppLockState()
	        let viewModel = AppLockViewModel(appLockState: appLockState, authenticator: authenticator, keychainStore: keychain)

	        await viewModel.setAppLockEnabled(true)

	        XCTAssertTrue(viewModel.isLockEnabled)
	        XCTAssertTrue(keychain.hasUnlockToken())
	    }

	    func testEnableFailureLeavesToggleOffAndNoKeychainMarker() async {
	        let keychain = InMemoryAppLockStore()
	        let authenticator = TestBiometricAuthenticator(result: .failure(.authenticationFailed))
	        let appLockState = AppLockState()
	        let viewModel = AppLockViewModel(appLockState: appLockState, authenticator: authenticator, keychainStore: keychain)

	        await viewModel.setAppLockEnabled(true)

	        XCTAssertFalse(viewModel.isLockEnabled)
	        XCTAssertFalse(keychain.hasUnlockToken())
	    }

	    func testDisableRemovesKeychainMarkerAndTurnsOffToggle() async {
	        let keychain = InMemoryAppLockStore()
	        let authenticator = TestBiometricAuthenticator(result: .success)
	        let appLockState = AppLockState()
	        let viewModel = AppLockViewModel(appLockState: appLockState, authenticator: authenticator, keychainStore: keychain)

	        await viewModel.setAppLockEnabled(true)
	        await viewModel.setAppLockEnabled(false)

	        XCTAssertFalse(viewModel.isLockEnabled)
	        XCTAssertFalse(keychain.hasUnlockToken())
	    }

	    func testLockGatingRequiresKeychainMarker() async {
	        let keychain = InMemoryAppLockStore()
	        let authenticator = TestBiometricAuthenticator(result: .success)
	        let appLockState = AppLockState()
	        let viewModel = AppLockViewModel(appLockState: appLockState, authenticator: authenticator, keychainStore: keychain)

	        await viewModel.setAppLockEnabled(true)
	        viewModel.lock()
	        XCTAssertTrue(viewModel.isLocked)

        await viewModel.setAppLockEnabled(false)
        viewModel.lock()
        XCTAssertFalse(viewModel.isLocked)
    }
}

private final class InMemoryAppLockStore: AppLockKeychainStoring {
    private var hasToken = false

    func hasUnlockToken() -> Bool { hasToken }
    func storeUnlockToken() -> Bool {
        hasToken = true
        return true
    }
    func deleteUnlockToken() { hasToken = false }
}

private struct TestBiometricAuthenticator: BiometricAuthenticating {
    let result: BiometricAuthResult

    func supportedBiometryType() -> LABiometryType { .faceID }
    func canEvaluateDeviceOwnerAuthentication(errorOut: inout BiometricError?) -> Bool { true }
    func authenticate(reason: String) async -> BiometricAuthResult { result }
}
