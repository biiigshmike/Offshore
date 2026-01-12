import SwiftUI
import CoreData
import LocalAuthentication
import UserNotifications
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - SettingsView
/// Simplified Settings screen using plain SwiftUI containers.
/// Layout mirrors the original: grouped cards with rows and toggles.
struct SettingsView: View {
    // MARK: Env
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var appLockViewModel: AppLockViewModel
    
    // MARK: State
    @StateObject private var vm = SettingsViewModel()
    @State private var showResetAlert = false
    @State private var showMergeConfirm = false
    @State private var showForceReuploadConfirm = false
    @State private var showForceReuploadResult = false
    @State private var forceReuploadMessage: String = ""
    @State private var isMerging = false
    @State private var isForceReuploading = false
    @State private var showMergeDone = false
    @State private var showDisableCloudOptions = false
    @State private var isReconfiguringStores = false
    @StateObject private var cloudDiag = CloudDiagnostics.shared
    
    private enum SettingsRoute: Hashable {
        case appInfo
        case help
        case general
        case privacy
        case notifications
        case icloud
        case categories
        case presets
    }
    
    // Guided walkthrough removed
    
    var body: some View { settingsContent }
    
    private var settingsContent: some View {
        settingsList
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .ub_windowTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    WorkspaceMenuButton()
                }
            }
            .navigationDestination(for: SettingsRoute.self) { route in
                switch route {
                case .appInfo:
                    AppInfoView(
                        appName: appDisplayName,
                        appIconGraphic: appIconGraphic,
                        appStoreURL: appStoreURL,
                        developerURL: developerURL
                    )
                    .ub_windowTitle("About")
                case .help:
                    HelpView(wrapsInNavigation: false)
                        .ub_windowTitle("Help")
                case .general:
                    GeneralSettingsView(
                        vm: vm,
                        showResetAlert: $showResetAlert
                    )
                    .ub_windowTitle("General")
                case .privacy:
                    PrivacySettingsView(
                        biometricName: biometricName,
                        biometricIconName: biometricIconName,
                        supportsBiometrics: supportsBiometrics,
                        isLockEnabled: appLockToggleBinding
                    )
                    .ub_windowTitle("Privacy")
                case .notifications:
                    NotificationsSettingsView()
                        .ub_windowTitle("Notifications")
                case .icloud:
                    ICloudSettingsView(
                        cloudToggle: cloudToggleBinding,
                        widgetSyncToggle: $vm.syncHomeWidgetsAcrossDevices,
                        isForceReuploading: isForceReuploading,
                        isReconfiguringStores: isReconfiguringStores,
                        onForceRefresh: { showForceReuploadConfirm = true }
                    )
                    .ub_windowTitle("iCloud")
                case .categories:
                    ExpenseCategoryManagerView(wrapsInNavigation: false)
                        .environment(\.managedObjectContext, viewContext)
                        .ub_windowTitle("Categories")
                case .presets:
                    PresetsView()
                        .environment(\.managedObjectContext, viewContext)
                        .ub_windowTitle("Presets")
                }
            }
            .task { await cloudDiag.refresh() }
            .confirmationDialog("Turn Off iCloud Sync?", isPresented: $showDisableCloudOptions, titleVisibility: .visible) {
                Button("Switch to Local (Keep Data)", role: .destructive) { disableCloud(eraseLocal: false) }
                Button("Remove from This Device", role: .destructive) { disableCloud(eraseLocal: true) }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Choose what to do with your data on this device.")
            }
            .alert("Erase All Data?", isPresented: $showResetAlert) {
                Button("Remove Data & Reset App", role: .destructive) { performDataWipe() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove all budgets, cards, incomes, and expenses. This action cannot be undone.")
            }
            .alert("Merge Local Data into iCloud?", isPresented: $showMergeConfirm) {
                Button("Merge", role: .none) { runMerge() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will look for duplicate items across devices and collapse them to avoid duplicates. Your data remains in iCloud; this action cannot be undone.")
            }
            .alert("Merge Complete", isPresented: $showMergeDone) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your data has been merged. If you still see duplicates, you can run the merge again or contact support.")
            }
            .alert("Force iCloud Sync Refresh?", isPresented: $showForceReuploadConfirm) {
                Button("Run Refresh", role: .destructive) { forceReupload() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will mark all budgets, incomes, and expenses as updated so they re-export to iCloud. Use for troubleshooting only.")
            }
            .alert("Sync Refresh Finished", isPresented: $showForceReuploadResult) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(forceReuploadMessage)
            }
            .overlay(alignment: .center) {
                if let overlayLabel = overlayStatusLabel {
                    ZStack {
                        Color.black.opacity(0.3).ignoresSafeArea()
                        VStack(spacing: Spacing.m) {
                            ProgressView()
                            Text(overlayLabel).foregroundStyle(Colors.styleSecondary)
                        }
                        .padding(Spacing.l)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }
    }
    
    private var settingsList: some View {
        List {
            appSection
            generalSection
            categoriesSection
            presetsSection
        }
    }
    
    @ViewBuilder
    private var appSection: some View {
        Section {
            NavigationLink(value: SettingsRoute.appInfo) {
                AppInfoRow(
                    appName: appDisplayName,
                    appIconGraphic: appIconGraphic
                )
            }
            
            NavigationLink(value: SettingsRoute.help) {
                DesignSystemV2.SettingsRow(
                    title: "Help",
                    showsChevron: false,
                    iconSystemName: "questionmark.circle",
                    iconStyle: SettingsIconStyle.gray,
                    leadingFactory: settingsLeadingIcon
                )
            }
        }
    }
    
    @ViewBuilder
    private var generalSection: some View {
        Section {
            NavigationLink(value: SettingsRoute.general) {
                DesignSystemV2.SettingsRow(
                    title: "General",
                    showsChevron: false,
                    iconSystemName: "gear",
                    iconStyle: SettingsIconStyle.gray,
                    leadingFactory: settingsLeadingIcon
                )
            }
            
            NavigationLink(value: SettingsRoute.privacy) {
                DesignSystemV2.SettingsRow(
                    title: "Privacy",
                    showsChevron: false,
                    iconSystemName: biometricIconName,
                    iconStyle: SettingsIconStyle.blue,
                    leadingFactory: settingsLeadingIcon
                )
            }
            
            NavigationLink(value: SettingsRoute.notifications) {
                DesignSystemV2.SettingsRow(
                    title: "Notifications",
                    showsChevron: false,
                    iconSystemName: "bell.badge",
                    iconStyle: SettingsIconStyle.red,
                    leadingFactory: settingsLeadingIcon
                )
            }
            
            NavigationLink(value: SettingsRoute.icloud) {
                DesignSystemV2.SettingsRow(
                    title: "iCloud",
                    showsChevron: false,
                    iconSystemName: "icloud",
                    iconStyle: SettingsIconStyle.blueOnWhite,
                    leadingFactory: settingsLeadingIcon
                )
            }
        }
    }
    
    @ViewBuilder
    private var categoriesSection: some View {
        Section {
            NavigationLink(value: SettingsRoute.categories) {
                DesignSystemV2.SettingsRow(
                    title: "Manage Categories",
                    showsChevron: false,
                    iconSystemName: "tag",
                    iconStyle: SettingsIconStyle.lightPurple,
                    leadingFactory: settingsLeadingIcon
                )
            }
            .accessibilityIdentifier(AccessibilityID.Settings.manageCategoriesNavigation)
        }
    }
    
    @ViewBuilder
    private var presetsSection: some View {
        Section {
            NavigationLink(value: SettingsRoute.presets) {
                DesignSystemV2.SettingsRow(
                    title: "Manage Presets",
                    showsChevron: false,
                    iconSystemName: "list.bullet.rectangle",
                    iconStyle: SettingsIconStyle.orange,
                    leadingFactory: settingsLeadingIcon
                )
            }
            .accessibilityIdentifier(AccessibilityID.Settings.managePresetsNavigation)
        }
    }
    
    // MARK: Data wipe
    private func performDataWipe() {
        do {
            try CoreDataService.shared.wipeAllData()
            UbiquitousFlags.clearHasCloudData()
        } catch {
            // No-op simple path
        }
    }
    
    private func runMerge() {
        isMerging = true
        Task { @MainActor in
            do {
                try MergeService.shared.mergeLocalDataIntoCloud()
                isMerging = false
                showMergeDone = true
            } catch {
                isMerging = false
                showMergeDone = true
            }
        }
    }
    
    private func disableCloud(eraseLocal: Bool) {
        isReconfiguringStores = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 80_000_000)
            await CoreDataService.shared.applyCloudSyncPreferenceChange(enableSync: false)
            vm.enableCloudSync = false
            let personalID = WorkspaceService.shared.personalWorkspace()?.id
            ?? WorkspaceService.shared.ensureActiveWorkspaceID()
            await WorkspaceService.shared.assignWorkspaceIDIfMissing(to: personalID)
            if eraseLocal {
                do { try CoreDataService.shared.wipeAllData() } catch { }
                UbiquitousFlags.clearHasCloudData()
            }
            await cloudDiag.refresh()
            isReconfiguringStores = false
        }
    }
    
    // Guided walkthrough removed
}

private extension SettingsView {
    var cloudToggleBinding: Binding<Bool> {
        Binding<Bool>(
            get: { vm.enableCloudSync },
            set: { newValue in
                if vm.enableCloudSync && newValue == false {
                    showDisableCloudOptions = true
                    return
                }
                if !vm.enableCloudSync && newValue == true {
                    isReconfiguringStores = true
                    vm.enableCloudSync = true
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 80_000_000)
                        await CoreDataService.shared.applyCloudSyncPreferenceChange(enableSync: true)
                        let personalID = WorkspaceService.shared.personalWorkspace()?.id
                        ?? WorkspaceService.shared.ensureActiveWorkspaceID()
                        await WorkspaceService.shared.assignWorkspaceIDIfMissing(to: personalID)
                        // Workspace-backed period will mirror via Core Data
                        await cloudDiag.refresh()
                        isReconfiguringStores = false
                    }
                }
            }
        )
    }
    
    var overlayStatusLabel: String? {
        if isMerging { return "Merging data…" }
        if isReconfiguringStores { return "Reconfiguring storage…" }
        if isForceReuploading { return "Refreshing iCloud sync…" }
        return nil
    }
    
    /// Force a CloudKit re-export by "touching" all syncable entities.
    /// Uses ForceReuploadHelper to create history entries without user-visible changes.
    private func forceReupload() {
        isForceReuploading = true
        Task { @MainActor in
            defer { isForceReuploading = false }
            do {
                let result = try await ForceReuploadHelper.forceReuploadAll(reason: "settings-button")
                let summary = result.updatedCounts
                    .sorted(by: { $0.key < $1.key })
                    .map { "\($0.key): \($0.value)" }
                    .joined(separator: ", ")
                forceReuploadMessage = "Updated \(result.totalUpdated) records. \(summary.isEmpty ? "" : "Details: \(summary)")"
            } catch {
                forceReuploadMessage = "Failed to refresh: \(error.localizedDescription)"
            }
            showForceReuploadResult = true
        }
    }
    
    // Removed: Store Mode and Container Reachable rows for a cleaner UI
}

// Intentionally empty: SettingsRow is defined in SettingsViewModel.swift

private extension SettingsView {
    var biometricType: LABiometryType {
        BiometricAuthenticationManager.shared.supportedBiometryType()
    }
    
    var biometricName: String {
        if biometricType == .touchID { return "Touch ID" }
        if biometricType == .faceID { return "Face ID" }
        return "Biometrics"
    }
    
    var biometricIconName: String {
        if biometricType == .touchID { return "touchid" }
        if biometricType == .faceID { return "faceid" }
        return "lock"
    }
    
    var supportsBiometrics: Bool {
        biometricType != .none
    }
    
    var appDisplayName: String {
        let info = Bundle.main.infoDictionary
        let name = info?["CFBundleDisplayName"] as? String
        let bundleName = info?["CFBundleName"] as? String
        return name ?? bundleName ?? "App"
    }
    
    var appIconGraphic: AppIconGraphic {
        AppIconProvider.currentIconGraphic ?? .system(name: "square.fill")
    }
    
    var appStoreURL: URL {
        URL(string: "https://apple.com")!
    }
    
    var developerURL: URL {
        URL(string: "https://offshore-budgeting.notion.site/Offshore-Budgeting-295b42cd2e6c80cf817dd73a5761bb7e")!
    }
}

private extension SettingsView {
    var appLockToggleBinding: Binding<Bool> {
        Binding(
            get: { appLockViewModel.isLockEnabledPublished },
            set: { newValue in
                Task { await appLockViewModel.setAppLockEnabled(newValue) }
            }
        )
    }
}

private struct SettingsRowLabel: View {
    let iconSystemName: String
    let title: String
    var showsChevron: Bool = true
    var iconStyle: SettingsIconStyle = .gray
    @ScaledMetric(relativeTo: .body) private var iconTextSpacing: CGFloat = Spacing.l
    
    var body: some View {
        HStack(spacing: iconTextSpacing) {
            SettingsIconTile(
                systemName: iconSystemName,
                style: iconStyle
            )
            Text(title)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            if showsChevron {
                Image(systemName: Icons.sfChevronRight)
                    .font(Typography.footnote)
                    .foregroundStyle(Colors.styleSecondary)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(title))
    }
}

// Keep `style` explicit at call sites to preserve the exact icon appearance (and avoid inference drift) as Settings rows are refactored.
private func settingsLeadingIcon(systemName: String, style: SettingsIconStyle) -> SettingsIconTile {
    SettingsIconTile(systemName: systemName, style: style)
}

private enum SettingsIconStyle {
    case gray
    case blue
    case blueOnWhite
    case red
    case lightPurple
    case orange
    
    var tint: Color {
        switch self {
        case .gray:
            return Color(.systemGray)
        case .blue, .blueOnWhite:
            return Color(.systemBlue)
        case .red:
            return Color(.systemRed)
        case .lightPurple:
            return Color(.systemPurple)
        case .orange:
            return Color(.systemOrange)
        }
    }
    
    var background: Color {
        switch self {
        case .gray:
            return Color(.systemGray5)
        case .blue:
            return Color(.systemBlue).opacity(0.2)
        case .blueOnWhite:
            return Color(.systemBackground)
        case .red:
            return Color(.systemRed).opacity(0.2)
        case .lightPurple:
            return Color(.systemPurple).opacity(0.2)
        case .orange:
            return Color(.systemOrange).opacity(0.2)
        }
    }
    
    var usesStroke: Bool {
        switch self {
        case .blueOnWhite:
            return true
        default:
            return false
        }
    }
}

private struct SettingsIconTile: View {
    let systemName: String
    let style: SettingsIconStyle
    @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 28
    @ScaledMetric(relativeTo: .body) private var cornerRadius: CGFloat = 7
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(style.background)
            Image(systemName: systemName)
                .symbolRenderingMode(.monochrome)
                .font(.body.weight(.semibold))
                .foregroundStyle(style.tint)
        }
        .frame(width: iconSize, height: iconSize)
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(style.tint.opacity(style.usesStroke ? 0.25 : 0), lineWidth: 0.5)
        )
        .accessibilityHidden(true)
    }
}

private struct AppInfoRow: View {
    let appName: String
    let appIconGraphic: AppIconGraphic
    
    var body: some View {
        HStack(spacing: 14) {
            AppIconImageView(
                graphic: appIconGraphic,
                size: 75,
                shape: .circle
            )
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(appName)
                    .font(Typography.headline)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                Text("About")
                    .font(Typography.subheadline)
                    .foregroundStyle(Colors.styleSecondary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, Spacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(appName), About"))
    }
}

private struct AppInfoView: View {
    let appName: String
    let appIconGraphic: AppIconGraphic
    let appStoreURL: URL
    let developerURL: URL
    
    var body: some View {
        List {
            Section {
                VStack(spacing: Spacing.m) {
                    AppIconImageView(
                        graphic: appIconGraphic,
                        size: appInfoIconSize,
                        shape: .squircle
                    )
                    Text(appName)
                        .font(.title2).bold()
                    Text(appVersionLine)
                        .font(Typography.subheadline)
                        .foregroundStyle(Colors.styleSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, Spacing.l)
                .listRowInsets(EdgeInsets())
            }
            
            Section {
                Link(destination: appStoreURL) {
                    DesignSystemV2.SettingsRow(
                        title: "View in App Store",
                        iconSystemName: "arrow.up.right.square",
                        iconStyle: SettingsIconStyle.gray,
                        leadingFactory: settingsLeadingIcon
                    )
                }
                
                Link(destination: developerURL) {
                    DesignSystemV2.SettingsRow(
                        title: "Developer Website",
                        iconSystemName: "safari",
                        iconStyle: SettingsIconStyle.gray,
                        leadingFactory: settingsLeadingIcon
                    )
                }
            }
            
            Section {
                NavigationLink {
                    ReleaseLogsView()
                } label: {
                    DesignSystemV2.SettingsRow(
                        title: "Release Logs",
                        showsChevron: false,
                        iconSystemName: "list.clipboard",
                        iconStyle: SettingsIconStyle.gray,
                        leadingFactory: settingsLeadingIcon
                    )
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("About")
        .ub_windowTitle("About")
    }
    
    private var appVersionLine: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "-"
        let build = info?["CFBundleVersion"] as? String ?? "-"
        return "Version \(version) • Build \(build)"
    }
    
    private var appInfoIconSize: CGFloat {
#if os(iOS)
        let width = UIScreen.main.bounds.width
#elseif os(macOS)
        let width = NSScreen.main?.frame.width ?? 480
#else
        let width: CGFloat = 480
#endif
        let scaled = min(width * 0.36, 200)
        return max(120, scaled)
    }
}

private struct ReleaseLogsView: View {
    var body: some View {
        List {
            ForEach(AppUpdateLogs.releaseLogs) { log in
                Section(header: Text(releaseTitle(for: log.versionToken))) {
                    ForEach(log.content.items) { item in
                        ReleaseLogItemRow(item: item)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Release Logs")
        .ub_windowTitle("Release Logs")
    }
    
    private func releaseTitle(for versionToken: String) -> String {
        let parts = versionToken.split(separator: ".")
        guard parts.count >= 2 else { return "What's New • \(versionToken)" }
        let build = String(parts.last ?? "")
        let version = parts.dropLast().joined(separator: ".")
        return "What's New • \(version) (Build \(build))"
    }
}

private struct ReleaseLogItemRow: View {
    let item: TipsItem
    @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 22
    
    var body: some View {
        HStack(alignment: .top, spacing: Spacing.m) {
            Image(systemName: item.symbolName)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundStyle(Colors.styleSecondary)
                .frame(width: iconSize + 12, alignment: .center)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(item.title)
                    .font(Typography.headline)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                Text(item.detail)
                    .font(Typography.subheadline)
                    .foregroundStyle(Colors.styleSecondary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, Spacing.xxs)
        .accessibilityElement(children: .combine)
    }
}

private struct GeneralSettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var vm: SettingsViewModel
    @Binding var showResetAlert: Bool
    @State private var selectedBudgetPeriod: BudgetPeriod = .monthly
    
    var body: some View {
        List {
            Section {
                Toggle("Confirm Before Deleting", isOn: $vm.confirmBeforeDelete)
                Picker("Default Budget Period", selection: $selectedBudgetPeriod) {
                    ForEach(BudgetPeriod.selectableCases) { Text($0.displayName).tag($0) }
                }
            }
            
            Section {
                tipsResetButton
            }
            
            Section {
                let label = Text("Delete Data & Reset")
                    .font(Typography.subheadlineSemibold)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)

                DesignSystemV2.Buttons.DestructiveCTA(
                    tint: .red,
                    action: { showResetAlert = true },
                    label: { label },
                    legacyStyle: { button in
                        button
                            .buttonStyle(.plain)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(
                                        {
#if canImport(UIKit)
                                            return Color(UIColor { traits in
                                                traits.userInterfaceStyle == .dark ? UIColor(white: 0.18, alpha: 1) : UIColor(white: 0.94, alpha: 1)
                                            })
#elseif canImport(AppKit)
                                            return Color(nsColor: NSColor.windowBackgroundColor)
#else
                                            return Colors.grayOpacity02
#endif
                                        }()
                                    )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                )
                .listRowInsets(EdgeInsets())
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("General")
        .ub_windowTitle("General")
        .onAppear {
            selectedBudgetPeriod = WorkspaceService.shared.currentBudgetPeriod(in: viewContext)
        }
        .onChange(of: selectedBudgetPeriod) { newValue in
            WorkspaceService.shared.setBudgetPeriod(newValue, in: viewContext)
        }
    }
    
    @ViewBuilder
    private var tipsResetButton: some View {
        let label = Text("Reset Tips & Hints")
            .font(Typography.subheadlineSemibold)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)

        DesignSystemV2.Buttons.PrimaryCTA(
            tint: .orange,
            action: { TipsAndHintsStore.shared.resetAllTips() },
            label: { label },
            legacyStyle: { button in
                button.buttonStyle(.plain)
            }
        )
        .listRowInsets(EdgeInsets())
    }
    
}

private struct PrivacySettingsView: View {
    let biometricName: String
    let biometricIconName: String
    let supportsBiometrics: Bool
    @Binding var isLockEnabled: Bool
    @EnvironmentObject private var appLockViewModel: AppLockViewModel
    @Environment(\.uiTestingFlags) private var uiTestingFlags
    
    var body: some View {
        let footerText = supportsBiometrics
        ? "Requires a device passcode. Use \(biometricName) when available."
        : "Requires a device passcode to be set."
        
        return List {
            Section {
                Toggle("Use App Lock", isOn: $isLockEnabled)
                    .disabled(!appLockViewModel.isDeviceAuthAvailable || appLockViewModel.isToggleInFlight)
                    .accessibilityIdentifier(AccessibilityID.Settings.Privacy.appLockToggle)
            } footer: {
                Text(footerText)
            }
            if let availabilityMessage = appLockViewModel.availabilityMessage {
                Section {
                    Text(availabilityMessage)
                        .font(Typography.footnote)
                        .foregroundStyle(Colors.styleSecondary)
                }
            }
#if DEBUG
            if uiTestingFlags.isUITesting {
                Section {
                    Text("UI Test App Lock: allow=\(uiTestingFlags.allowAppLock ? "1" : "0"), available=\(appLockViewModel.isDeviceAuthAvailable ? "1" : "0")")
                        .font(Typography.footnote)
                        .foregroundStyle(Colors.styleSecondary)
                        .accessibilityIdentifier(AccessibilityID.Settings.Privacy.appLockUITestState)
                }
            }
#endif
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Privacy")
        .ub_windowTitle("Privacy")
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: Spacing.s) {
                    Image(systemName: biometricIconName)
                    Text("Privacy")
                }
            }
        }
        .task { appLockViewModel.refreshAvailability() }
    }
}

private struct NotificationsSettingsView: View {
    @AppStorage(AppSettingsKeys.enableDailyReminder.rawValue) private var enableDailyReminder: Bool = false
    @AppStorage(AppSettingsKeys.enablePlannedIncomeReminder.rawValue) private var enablePlannedIncomeReminder: Bool = false
    @AppStorage(AppSettingsKeys.enablePresetExpenseDueReminder.rawValue) private var enablePresetExpenseDueReminder: Bool = false
    @AppStorage(AppSettingsKeys.silencePresetWithActualAmount.rawValue) private var silencePresetWithActualAmount: Bool = false
    @AppStorage(AppSettingsKeys.excludeNonGlobalPresetExpenses.rawValue) private var excludeNonGlobalPresetExpenses: Bool = false
    @AppStorage(AppSettingsKeys.notificationReminderTimeMinutes.rawValue) private var reminderTimeMinutes: Int = 20 * 60
    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @State private var showPermissionAlert = false
    
    private let calendar: Calendar = .current
    
    var body: some View {
        List {
            Section("Expenses") {
                Toggle("Daily Expense Reminder", isOn: $enableDailyReminder)
            }
            
            Section("Income") {
                Toggle("Planned Income Reminder", isOn: $enablePlannedIncomeReminder)
            }
            
            Section("Presets") {
                Toggle("Preset Expense Due Reminder", isOn: $enablePresetExpenseDueReminder)
                Toggle("Silence If Actual Amount > 0", isOn: $silencePresetWithActualAmount)
                    .disabled(!enablePresetExpenseDueReminder)
                Toggle("Exclude Non-global Preset Expenses", isOn: $excludeNonGlobalPresetExpenses)
                    .disabled(!enablePresetExpenseDueReminder)
            }
            
            Section {
                DatePicker("Reminder Time", selection: reminderTimeBinding, displayedComponents: .hourAndMinute)
            } footer: {
                Text("Reminders are scheduled locally and never leave the device.")
            }
            
            Section {
                permissionButton
            }
            
            Section {
                settingsButton
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Notifications")
        .ub_windowTitle("Notifications")
        .task { await refreshAuthorizationStatus() }
        .onChange(of: enableDailyReminder) { _ in handleReminderToggleChange() }
        .onChange(of: enablePlannedIncomeReminder) { _ in handleReminderToggleChange() }
        .onChange(of: enablePresetExpenseDueReminder) { _ in handleReminderToggleChange() }
        .onChange(of: silencePresetWithActualAmount) { _ in Task { await LocalNotificationScheduler.shared.refreshAll() } }
        .onChange(of: excludeNonGlobalPresetExpenses) { _ in Task { await LocalNotificationScheduler.shared.refreshAll() } }
        .onChange(of: reminderTimeMinutes) { _ in Task { await LocalNotificationScheduler.shared.refreshAll() } }
        .alert("Notifications Disabled", isPresented: $showPermissionAlert) {
            Button("Open Settings") { openSystemSettings() }
            Button("OK", role: .cancel) { }
        } message: {
            Text("Enable notifications in iOS Settings to receive reminders.")
        }
    }
    
    @ViewBuilder
    private var permissionButton: some View {
        let isGranted = authorizationStatus == .authorized
        let label = HStack(spacing: Spacing.s) {
            Text(isGranted ? "Notification Permission Granted" : "Request Notification Permission")
            if isGranted {
                Image(systemName: "checkmark")
            }
        }
            .font(Typography.subheadlineSemibold)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)

        DesignSystemV2.Buttons.PrimaryCTA(
            tint: isGranted ? .green : .blue,
            action: { Task { await requestPermission() } },
            label: { label },
            legacyStyle: { button in
                button
                    .buttonStyle(.plain)
                    .foregroundStyle(Colors.white)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(isGranted ? Color.green : Color.blue)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        )
        .disabled(isGranted)
        .opacity(isGranted ? 0.85 : 1)
        .settingsListRowStyle(background: .colorsClear)
    }
    
    @ViewBuilder
    private var settingsButton: some View {
        let label = Text("Open System Settings")
            .font(Typography.subheadlineSemibold)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)

        DesignSystemV2.Buttons.SecondaryCTA(
            tint: .gray,
            action: openSystemSettings,
            label: { label },
            legacyStyle: { button in
                button
                    .buttonStyle(.plain)
                    .foregroundStyle(Colors.stylePrimary)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(settingsButtonBackground)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        )
        .settingsListRowStyle(background: .colorsClear)
    }
    
    private var settingsButtonBackground: Color {
#if canImport(UIKit)
        return Color(UIColor.systemGray4)
#elseif canImport(AppKit)
        return Color(nsColor: NSColor.windowBackgroundColor)
#else
        return Colors.grayOpacity02
#endif
    }
    
    private var reminderTimeBinding: Binding<Date> {
        Binding(
            get: {
                let hour = max(0, min(23, reminderTimeMinutes / 60))
                let minute = max(0, min(59, reminderTimeMinutes % 60))
                return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
            },
            set: { newValue in
                let comps = calendar.dateComponents([.hour, .minute], from: newValue)
                let hour = comps.hour ?? 20
                let minute = comps.minute ?? 0
                reminderTimeMinutes = max(0, min(24 * 60 - 1, hour * 60 + minute))
            }
        )
    }
    
    private func handleReminderToggleChange() {
        Task {
            await refreshAuthorizationStatus()
            guard enableDailyReminder || enablePlannedIncomeReminder || enablePresetExpenseDueReminder else {
                await LocalNotificationScheduler.shared.refreshAll()
                return
            }
            if authorizationStatus == .notDetermined {
                let granted = await LocalNotificationScheduler.shared.requestAuthorization()
                await refreshAuthorizationStatus()
                if !granted {
                    await disableRemindersAndAlert()
                    return
                }
            } else if authorizationStatus == .denied {
                await disableRemindersAndAlert()
                return
            }
            await LocalNotificationScheduler.shared.refreshAll()
        }
    }
    
    private func requestPermission() async {
        _ = await LocalNotificationScheduler.shared.requestAuthorization()
        await refreshAuthorizationStatus()
        await LocalNotificationScheduler.shared.refreshAll()
    }
    
    private func refreshAuthorizationStatus() async {
        let settings = await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                continuation.resume(returning: settings)
            }
        }
        await MainActor.run {
            authorizationStatus = settings.authorizationStatus
        }
    }
    
    @MainActor
    private func disableRemindersAndAlert() async {
        enableDailyReminder = false
        enablePlannedIncomeReminder = false
        enablePresetExpenseDueReminder = false
        showPermissionAlert = true
    }
    
    private func openSystemSettings() {
#if os(iOS)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
#elseif os(macOS)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
            NSWorkspace.shared.open(url)
        }
#endif
    }
}

private struct ICloudSettingsView: View {
    @Binding var cloudToggle: Bool
    @Binding var widgetSyncToggle: Bool
    let isForceReuploading: Bool
    let isReconfiguringStores: Bool
    let onForceRefresh: () -> Void
    @Environment(\.platformCapabilities) private var capabilities
    
    var body: some View {
        List {
            Section {
                Toggle("Enable iCloud Sync", isOn: $cloudToggle)
            }
            
            Section {
                Toggle("Sync Home Widgets Across Devices", isOn: $widgetSyncToggle)
                    .disabled(!cloudToggle)
            }
            
            Section {
                forceRefreshButton
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("iCloud")
        .ub_windowTitle("iCloud")
    }
    
    @ViewBuilder
    private var forceRefreshButton: some View {
        let isDisabled = isForceReuploading || isReconfiguringStores
        let label = HStack(spacing: Spacing.sPlus) {
            Image(systemName: "arrow.triangle.2.circlepath")
            Text("Force iCloud Sync Refresh")
                .font(Typography.headline)
        }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)

        if cloudToggle {
            DesignSystemV2.Buttons.DestructiveCTA(
                tint: .red,
                useGlassIfAvailable: capabilities.supportsOS26Translucency,
                action: onForceRefresh,
                label: { label },
                legacyStyle: { button in
                    button
                        .buttonStyle(.plain)
                        .foregroundStyle(Colors.white)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.red)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            )
            .disabled(isDisabled)
            .opacity(isDisabled ? 0.6 : 1)
            .settingsListRowStyle(background: .colorsClear)
        }
    }
}

private enum AppIconShape {
    case circle
    case squircle
}

private struct AppIconImageView: View {
    let graphic: AppIconGraphic
    let size: CGFloat
    let shape: AppIconShape
    
    @ViewBuilder
    var body: some View {
        let image = graphic.image
        switch shape {
        case .circle:
            image
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fill)
                .frame(width: size, height: size)
                .clipShape(Circle())
                .overlay(Circle().stroke(Colors.primaryOpacity008, lineWidth: 1))
        case .squircle:
            let mask = RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
            image
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: size, height: size)
                .clipShape(mask)
                .overlay(mask.stroke(Colors.primaryOpacity008, lineWidth: 1))
        }
    }
}

private enum AppIconProvider {
    static var currentIconGraphic: AppIconGraphic? {
        .asset(name: "SettingsAppIcon")
    }
}

private enum AppIconGraphic {
    case asset(name: String)
    case system(name: String)
    
    var image: Image {
        switch self {
        case .asset(let name):
            return Image(name)
        case .system(let name):
            return Image(systemName: name)
        }
    }
}
