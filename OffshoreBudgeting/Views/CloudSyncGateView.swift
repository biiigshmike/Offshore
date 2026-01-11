import SwiftUI

/// Entry gate shown whenever onboarding should occur. Presents the iCloud Sync
/// decision first (when available) and, if the user opts in, quickly probes for
/// existing cloud data to optionally skip onboarding entirely.
struct CloudSyncGateView: View {
    // MARK: Environment
    @Environment(\.uiTestingFlags) private var uiTesting
    @Environment(\.platformCapabilities) private var capabilities
    @EnvironmentObject private var themeManager: ThemeManager

    // MARK: App Storage
    @AppStorage("didCompleteOnboarding") private var didCompleteOnboarding: Bool = false
    @AppStorage(AppSettingsKeys.enableCloudSync.rawValue) private var enableCloudSync: Bool = false
    @AppStorage("didChooseCloudDataOnboarding") private var didChooseCloudDataOnboarding: Bool = false

    // MARK: Local State
    @State private var shouldShowOnboarding: Bool = false
    @State private var showFirstPrompt: Bool = false
    @State private var scanningForExisting: Bool = false
    @State private var showExistingDataPrompt: Bool = false
    @State private var existingDataFound: Bool = false
    @State private var preparingWorkspace: Bool = false

    var body: some View {
        ZStack {
            themeManager.selectedTheme.background
                .overlay(Color.black.opacity(capabilities.supportsOS26Translucency ? 0.04 : 0.06))
                .ignoresSafeArea()

            if preparingWorkspace {
                preparingView
            } else if scanningForExisting {
                scanningView
            } else if shouldShowOnboarding {
                OnboardingView()
            } else {
                // Idle placeholder while prompts decide the path
                Color.clear
            }
        }
        .onAppear { presentIfNeeded() }
        // First prompt: ask to enable iCloud
        .alert("Sync with iCloud?", isPresented: $showFirstPrompt) {
            Button("Use iCloud") { enableAndProbeForExistingData() }
            Button("Not Now", role: .cancel) { declineCloudThenOnboard() }
        } message: {
            Text("Use iCloud to keep your budgets in sync across your devices. You can change this later in Settings.")
        }
        // Second prompt: we detected existing Cloud data
        .alert("iCloud data found", isPresented: $showExistingDataPrompt) {
            Button("Use iCloud Data") { useExistingDataAndSkipOnboarding() }
            Button("Start Fresh", role: .cancel) { startFreshLocalOnboarding() }
        } message: {
            Text("We found budget data from another device. Would you like to use it on this device?")
        }
    }

    // MARK: Subviews
    private var preparingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Setting up your budget workspace…").foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var scanningView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Checking for existing iCloud data…").foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Flow Control
    private func presentIfNeeded() {
        if uiTesting.isUITesting {
            if let accountAvailable = uiTesting.cloudAccountAvailableOverride,
               let cloudDataExists = uiTesting.cloudDataExistsOverride {
                decideCloudOnboardingPath(
                    checker: UITestCloudAvailabilityChecker(
                        isCloudSyncEnabledSetting: enableCloudSync,
                        accountAvailable: accountAvailable,
                        cloudDataExists: cloudDataExists
                    )
                )
            } else {
                shouldShowOnboarding = true
            }
            return
        }

        if enableCloudSync {
            decideCloudOnboardingPath(checker: SystemCloudAvailabilityChecker())
        } else {
            presentStandardOnboardingFlow()
        }
    }

    private func decideCloudOnboardingPath(checker: CloudAvailabilityChecking) {
        Task { @MainActor in
            let engine = CloudOnboardingDecisionEngine(checker: checker)
            let decision = await engine.initialDecision()
            switch decision {
            case .promptForCloudDataChoice:
                if didChooseCloudDataOnboarding {
                    shouldShowOnboarding = true
                } else {
                    showExistingDataPrompt = true
                }
            case .proceedWithStandardOnboarding:
                presentStandardOnboardingFlow()
            }
        }
    }

    private func presentStandardOnboardingFlow() {
        Task { @MainActor in
            let available = await CloudAccountStatusProvider.shared.resolveAvailability(forceRefresh: false)
            if available {
                showFirstPrompt = true
            } else {
                // No iCloud available; proceed with local onboarding.
                shouldShowOnboarding = true
            }
        }
    }

    private func declineCloudThenOnboard() {
        if enableCloudSync {
            // If previously enabled, honor user's decision to go local for onboarding.
            enableCloudSync = false
            Task { @MainActor in
                await CoreDataService.shared.applyCloudSyncPreferenceChange(enableSync: false)
            }
        }
        shouldShowOnboarding = true
    }

    private func enableAndProbeForExistingData() {
        // Turn on Cloud sync up-front.
        enableCloudSync = true

        // If any device previously indicated cloud data exists, verify remotely first.
        if UbiquitousFlags.hasCloudData() {
            scanningForExisting = true
            Task { @MainActor in
                await CoreDataService.shared.applyCloudSyncPreferenceChange(enableSync: true)
                let remoteHasData = await CloudDataRemoteProbe().hasAnyRemoteData(timeout: 6.0)
                scanningForExisting = false
                if remoteHasData {
                    existingDataFound = true
                    showExistingDataPrompt = true
                } else {
                    // Flag was stale—continue with local scan/import path below.
                    proceedWithLocalScan()
                }
            }
            return
        }

        proceedWithLocalScan()
    }

    private func proceedWithLocalScan() {
        scanningForExisting = true
        Task { @MainActor in
            await CoreDataService.shared.applyCloudSyncPreferenceChange(enableSync: true)
            // Establish a shared cloud workspace ID and assign missing IDs.
            let personalID = WorkspaceService.shared.personalWorkspace()?.id
                ?? WorkspaceService.shared.ensureActiveWorkspaceID()
            await WorkspaceService.shared.assignWorkspaceIDIfMissing(to: personalID)
            // Quick probe to see if remote data appears via local import.
            let hasData = await CloudDataProbe().scanForExistingData(timeout: 3.0, pollInterval: 0.3)
            scanningForExisting = false
            if hasData {
                UbiquitousFlags.setHasCloudDataTrue()
                existingDataFound = true
                showExistingDataPrompt = true
            } else {
                // No prior data detected—continue with onboarding (Cloud enabled).
                shouldShowOnboarding = true
            }
        }
    }

    private func useExistingDataAndSkipOnboarding() {
        // Prepare workspace and wait briefly for initial Cloud import to surface data.
        preparingWorkspace = true
        didChooseCloudDataOnboarding = true
        if uiTesting.isUITesting {
            didCompleteOnboarding = true
            return
        }
        Task { @MainActor in
            // Kick off a short wait for import to finish; don't block forever.
            _ = await CloudSyncMonitor.shared.awaitInitialImport(timeout: 10.0, pollInterval: 0.2)
            didCompleteOnboarding = true
        }
    }

    private func startFreshLocalOnboarding() {
        didChooseCloudDataOnboarding = true
        // To avoid impacting existing Cloud data, disable sync and proceed locally.
        if enableCloudSync {
            enableCloudSync = false
            Task { @MainActor in
                await CoreDataService.shared.applyCloudSyncPreferenceChange(enableSync: false)
            }
        }
        shouldShowOnboarding = true
    }
}

private struct UITestCloudAvailabilityChecker: CloudAvailabilityChecking {
    let isCloudSyncEnabledSetting: Bool
    let accountAvailable: Bool
    let cloudDataExists: Bool

    func iCloudAccountAvailable() async -> Bool { accountAvailable }
    func cloudDataExists() async -> Bool { cloudDataExists }
}
