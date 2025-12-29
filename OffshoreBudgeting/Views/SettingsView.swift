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
    
    // MARK: State
    @StateObject private var vm = SettingsViewModel()
    @AppStorage("appLockEnabled") private var isLockEnabled: Bool = true
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

    // Guided walkthrough removed

    var body: some View { settingsContent }

    @ViewBuilder
    private var settingsContent: some View {
        List {
            Section {
                NavigationLink {
                    AppInfoView(
                        appName: appDisplayName,
                        appIconGraphic: appIconGraphic,
                        appStoreURL: appStoreURL,
                        developerURL: developerURL
                    )
                } label: {
                    AppInfoRow(
                        appName: appDisplayName,
                        appIconGraphic: appIconGraphic
                    )
                }

                NavigationLink(destination: HelpView()) {
                    SettingsRowLabel(
                        iconSystemName: "questionmark.circle",
                        title: "Help",
                        showsChevron: false,
                        iconStyle: .gray
                    )
                }

            }

            Section {
                NavigationLink {
                    GeneralSettingsView(
                        vm: vm,
                        showResetAlert: $showResetAlert
                    )
                } label: {
                    SettingsRowLabel(
                        iconSystemName: "gear",
                        title: "General",
                        showsChevron: false,
                        iconStyle: .gray
                    )
                }

                NavigationLink {
                    PrivacySettingsView(
                        biometricName: biometricName,
                        biometricIconName: biometricIconName,
                        isLockEnabled: $isLockEnabled
                    )
                } label: {
                    SettingsRowLabel(
                        iconSystemName: biometricIconName,
                        title: "Privacy",
                        showsChevron: false,
                        iconStyle: .blue
                    )
                }

                NavigationLink {
                    NotificationsSettingsView()
                } label: {
                    SettingsRowLabel(
                        iconSystemName: "bell.badge",
                        title: "Notifications",
                        showsChevron: false,
                        iconStyle: .orange
                    )
                }

                NavigationLink {
                    ICloudSettingsView(
                        cloudToggle: cloudToggleBinding,
                        widgetSyncToggle: $vm.syncHomeWidgetsAcrossDevices,
                        isForceReuploading: isForceReuploading,
                        isReconfiguringStores: isReconfiguringStores,
                        onForceRefresh: { showForceReuploadConfirm = true }
                    )
                } label: {
                    SettingsRowLabel(
                        iconSystemName: "icloud",
                        title: "iCloud",
                        showsChevron: false,
                        iconStyle: .blueOnWhite
                    )
                }
            }

            Section {
                NavigationLink {
                    ExpenseCategoryManagerView()
                        .environment(\.managedObjectContext, viewContext)
                } label: {
                    SettingsRowLabel(
                        iconSystemName: "tag",
                        title: "Manage Categories",
                        showsChevron: false,
                        iconStyle: .lightPurple
                    )
                }
            }

            Section {
                NavigationLink {
                    PresetsView()
                        .environment(\.managedObjectContext, viewContext)
                } label: {
                    SettingsRowLabel(
                        iconSystemName: "list.number.badge.ellipsis",
                        title: "Manage Presets",
                        showsChevron: false,
                        iconStyle: .orange
                    )
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Settings")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                WorkspaceMenuButton()
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
            Button("Reset", role: .destructive) { performDataWipe() }
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
                    VStack(spacing: 12) {
                        ProgressView()
                        Text(overlayLabel).foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
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

private struct SettingsRowLabel: View {
    let iconSystemName: String
    let title: String
    var showsChevron: Bool = true
    var iconStyle: SettingsIconStyle = .gray

    var body: some View {
        HStack(spacing: 12) {
            SettingsIconTile(
                systemName: iconSystemName,
                style: iconStyle
            )
            Text(title)
            Spacer()
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private enum SettingsIconStyle {
    case gray
    case blue
    case blueOnWhite
    case lightPurple
    case orange

    var tint: Color {
        switch self {
        case .gray:
            return Color(.systemGray)
        case .blue, .blueOnWhite:
            return Color(.systemBlue)
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

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(style.background)
            Image(systemName: systemName)
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(style.tint)
        }
        .frame(width: 28, height: 28)
        .overlay(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .stroke(style.tint.opacity(style.usesStroke ? 0.25 : 0), lineWidth: 0.5)
        )
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
            VStack(alignment: .leading, spacing: 4) {
                Text(appName)
                    .font(.headline)
                Text("About")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
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
                VStack(spacing: 12) {
                    AppIconImageView(
                        graphic: appIconGraphic,
                        size: appInfoIconSize,
                        shape: .squircle
                    )
                    Text(appName)
                        .font(.title2).bold()
                    Text(appVersionLine)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 16)
                .listRowInsets(EdgeInsets())
            }

            Section {
                Link(destination: appStoreURL) {
                    SettingsRowLabel(
                        iconSystemName: "arrow.up.right.square",
                        title: "View in App Store"
                    )
                }

                Link(destination: developerURL) {
                    SettingsRowLabel(
                        iconSystemName: "safari",
                        title: "Developer Website"
                    )
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("About")
    }

    private var appVersionLine: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "-"
        let build = info?["CFBundleVersion"] as? String ?? "-"
        return "Version \(version) (\(build))"
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

private struct GeneralSettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var vm: SettingsViewModel
    @Binding var showResetAlert: Bool

    var body: some View {
        List {
            Section {
                Toggle("Confirm Before Deleting", isOn: $vm.confirmBeforeDelete)
                Picker("Default Budget Period", selection: budgetPeriodBinding) {
                    ForEach(BudgetPeriod.selectableCases) { Text($0.displayName).tag($0) }
                }
            }

            Section {
                tipsResetButton
            }

            Section {
                let label = Text("Reset")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44, maxHeight: 44)

                if #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *) {
                    Button(role: .destructive) {
                        showResetAlert = true
                    } label: {
                        label
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.red)
                    .listRowInsets(EdgeInsets())
                } else {
                    Button(role: .destructive) {
                        showResetAlert = true
                    } label: {
                        label
                    }
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
                                    return Color.gray.opacity(0.2)
                                    #endif
                                }()
                            )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .listRowInsets(EdgeInsets())
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("General")
    }

    @ViewBuilder
    private var tipsResetButton: some View {
        let label = Text("Reset Tips & Hints")
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44, maxHeight: 44)

        if #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *) {
            Button {
                TipsAndHintsStore.shared.resetAllTips()
            } label: {
                label
            }
            .buttonStyle(.glassProminent)
            .tint(.orange)
            .listRowInsets(EdgeInsets())
        } else {
            Button {
                TipsAndHintsStore.shared.resetAllTips()
            } label: {
                label
            }
            .buttonStyle(.plain)
            .listRowInsets(EdgeInsets())
        }
    }

    private var budgetPeriodBinding: Binding<BudgetPeriod> {
        Binding(
            get: { WorkspaceService.shared.currentBudgetPeriod(in: viewContext) },
            set: { WorkspaceService.shared.setBudgetPeriod($0, in: viewContext) }
        )
    }
}

private struct PrivacySettingsView: View {
    let biometricName: String
    let biometricIconName: String
    @Binding var isLockEnabled: Bool

    var body: some View {
        List {
            Section {
                Toggle("Enable \(biometricName)", isOn: $isLockEnabled)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(biometricName)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    Image(systemName: biometricIconName)
                    Text(biometricName)
                }
            }
        }
    }
}

private struct NotificationsSettingsView: View {
    @AppStorage(AppSettingsKeys.enableDailyReminder.rawValue) private var enableDailyReminder: Bool = false
    @AppStorage(AppSettingsKeys.enablePlannedIncomeReminder.rawValue) private var enablePlannedIncomeReminder: Bool = false
    @AppStorage(AppSettingsKeys.notificationReminderTimeMinutes.rawValue) private var reminderTimeMinutes: Int = 20 * 60
    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @State private var showPermissionAlert = false

    private let calendar: Calendar = .current

    var body: some View {
        List {
            Section {
                Toggle("Daily Expense Reminder", isOn: $enableDailyReminder)
                Toggle("Planned Income Reminder", isOn: $enablePlannedIncomeReminder)
                DatePicker("Reminder Time", selection: reminderTimeBinding, displayedComponents: .hourAndMinute)
            } footer: {
                Text("Reminders are scheduled locally and never leave the device.")
            }

            Section {
                LabeledContent("Status", value: authorizationStatusLabel)

                Button("Request Notification Permission") {
                    Task { await requestPermission() }
                }
                .disabled(authorizationStatus == .authorized)

                Button("Open System Settings") {
                    openSystemSettings()
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Notifications")
        .task { await refreshAuthorizationStatus() }
        .onChange(of: enableDailyReminder) { _ in handleReminderToggleChange() }
        .onChange(of: enablePlannedIncomeReminder) { _ in handleReminderToggleChange() }
        .onChange(of: reminderTimeMinutes) { _ in Task { await LocalNotificationScheduler.shared.refreshAll() } }
        .alert("Notifications Disabled", isPresented: $showPermissionAlert) {
            Button("Open Settings") { openSystemSettings() }
            Button("OK", role: .cancel) { }
        } message: {
            Text("Enable notifications in iOS Settings to receive reminders.")
        }
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

    private var authorizationStatusLabel: String {
        switch authorizationStatus {
        case .authorized:
            return "Allowed"
        case .denied:
            return "Not allowed"
        case .provisional:
            return "Provisional"
        case .ephemeral:
            return "Ephemeral"
        case .notDetermined:
            return "Not determined"
        @unknown default:
            return "Unknown"
        }
    }

    private func handleReminderToggleChange() {
        Task {
            await refreshAuthorizationStatus()
            guard enableDailyReminder || enablePlannedIncomeReminder else {
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
    }

    @ViewBuilder
    private var forceRefreshButton: some View {
        let isDisabled = isForceReuploading || isReconfiguringStores
        let label = HStack(spacing: 10) {
            Image(systemName: "arrow.triangle.2.circlepath")
            Text("Force iCloud Sync Refresh")
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 44, maxHeight: 44)

        if cloudToggle,
           capabilities.supportsOS26Translucency,
           #available(iOS 26.0, macOS 26.0, macCatalyst 26.0, *) {
            Button(action: onForceRefresh) {
                label
            }
            .buttonStyle(.glassProminent)
            .tint(.red)
            .disabled(isDisabled)
            .opacity(isDisabled ? 0.6 : 1)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        } else if cloudToggle {
            Button(action: onForceRefresh) {
                label
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.red)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .disabled(isDisabled)
            .opacity(isDisabled ? 0.6 : 1)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
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
                .overlay(Circle().stroke(Color.primary.opacity(0.08), lineWidth: 1))
        case .squircle:
            let mask = RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
            image
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: size, height: size)
                .clipShape(mask)
                .overlay(mask.stroke(Color.primary.opacity(0.08), lineWidth: 1))
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
