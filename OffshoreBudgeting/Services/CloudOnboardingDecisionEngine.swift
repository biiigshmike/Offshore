import Foundation

// MARK: - CloudAvailabilityChecking
protocol CloudAvailabilityChecking {
    var isCloudSyncEnabledSetting: Bool { get }
    func iCloudAccountAvailable() async -> Bool
    func cloudDataExists() async -> Bool
}

// MARK: - CloudOnboardingDecision
enum CloudOnboardingDecision: Equatable {
    case proceedWithStandardOnboarding
    case promptForCloudDataChoice
}

enum CloudDataChoice {
    case useICloudData
    case startFresh
}

enum CloudOnboardingResolution: Equatable {
    case skipOnboarding
    case startOnboarding
}

// MARK: - CloudOnboardingDecisionEngine
struct CloudOnboardingDecisionEngine {
    let checker: CloudAvailabilityChecking

    func initialDecision() async -> CloudOnboardingDecision {
        guard checker.isCloudSyncEnabledSetting else { return .proceedWithStandardOnboarding }
        let accountAvailable = await checker.iCloudAccountAvailable()
        guard accountAvailable else { return .proceedWithStandardOnboarding }
        let hasCloudData = await checker.cloudDataExists()
        return hasCloudData ? .promptForCloudDataChoice : .proceedWithStandardOnboarding
    }

    func resolveChoice(_ choice: CloudDataChoice) -> CloudOnboardingResolution {
        switch choice {
        case .useICloudData:
            return .skipOnboarding
        case .startFresh:
            return .startOnboarding
        }
    }
}

// MARK: - SystemCloudAvailabilityChecker
final class SystemCloudAvailabilityChecker: CloudAvailabilityChecking {
    var isCloudSyncEnabledSetting: Bool {
        UserDefaults.standard.bool(forKey: AppSettingsKeys.enableCloudSync.rawValue)
    }

    func iCloudAccountAvailable() async -> Bool {
        await CloudAccountStatusProvider.shared.resolveAvailability(forceRefresh: false)
    }

    func cloudDataExists() async -> Bool {
        if UbiquitousFlags.hasCloudData() { return true }
        let remoteHasData = await CloudDataRemoteProbe().hasAnyRemoteData(timeout: 4.0)
        if remoteHasData {
            UbiquitousFlags.setHasCloudDataTrue()
        }
        return remoteHasData
    }
}
