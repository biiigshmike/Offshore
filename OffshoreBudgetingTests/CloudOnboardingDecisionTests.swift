import XCTest
@testable import Offshore

@MainActor
final class CloudOnboardingDecisionTests: XCTestCase {
    func testCloudDataPresentRequiresDecisionAndResolvesBranches() async {
        let checker = FakeCloudAvailabilityChecker(
            isCloudSyncEnabledSetting: true,
            accountAvailable: true,
            cloudDataExists: true
        )
        let engine = CloudOnboardingDecisionEngine(checker: checker)

        let decision = await engine.initialDecision()
        XCTAssertEqual(decision, .promptForCloudDataChoice)

        XCTAssertEqual(engine.resolveChoice(.useICloudData), .skipOnboarding)
        XCTAssertEqual(engine.resolveChoice(.startFresh), .startOnboarding)
    }

    func testCloudSyncDisabledSkipsDecision() async {
        let checker = FakeCloudAvailabilityChecker(
            isCloudSyncEnabledSetting: false,
            accountAvailable: true,
            cloudDataExists: true
        )
        let engine = CloudOnboardingDecisionEngine(checker: checker)

        let decision = await engine.initialDecision()
        XCTAssertEqual(decision, .proceedWithStandardOnboarding)
    }

    func testAccountUnavailableSkipsDecision() async {
        let checker = FakeCloudAvailabilityChecker(
            isCloudSyncEnabledSetting: true,
            accountAvailable: false,
            cloudDataExists: true
        )
        let engine = CloudOnboardingDecisionEngine(checker: checker)

        let decision = await engine.initialDecision()
        XCTAssertEqual(decision, .proceedWithStandardOnboarding)
    }

    func testNoCloudDataSkipsDecision() async {
        let checker = FakeCloudAvailabilityChecker(
            isCloudSyncEnabledSetting: true,
            accountAvailable: true,
            cloudDataExists: false
        )
        let engine = CloudOnboardingDecisionEngine(checker: checker)

        let decision = await engine.initialDecision()
        XCTAssertEqual(decision, .proceedWithStandardOnboarding)
    }
}

private struct FakeCloudAvailabilityChecker: CloudAvailabilityChecking {
    let isCloudSyncEnabledSetting: Bool
    let accountAvailable: Bool
    let cloudDataExists: Bool

    func iCloudAccountAvailable() async -> Bool { accountAvailable }
    func cloudDataExists() async -> Bool { cloudDataExists }
}
