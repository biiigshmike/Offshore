//
//  SettingsViewModel.swift
//  SoFar
//
//  Created by Michael Brown on 8/14/25.
//

import SwiftUI
import Combine

// MARK: - SettingsViewModel
/// Observable settings source of truth. Persists via @AppStorage for simplicity.
/// Properties trigger view updates by sending `objectWillChange` on write.
@MainActor
final class SettingsViewModel: ObservableObject {

    /// When true, show a confirmation dialog before deleting items.
    @AppStorage(AppSettingsKeys.confirmBeforeDelete.rawValue)
    var confirmBeforeDelete: Bool = true { willSet { objectWillChange.send() } }

    /// Controls whether the income calendar presents horizontally.
    @AppStorage(AppSettingsKeys.calendarHorizontal.rawValue)
    var calendarHorizontal: Bool = true { willSet { objectWillChange.send() } }

    /// When adding from Presets, default "Use in future budgets?" to ON.
    @AppStorage(AppSettingsKeys.presetsDefaultUseInFutureBudgets.rawValue)
    var presetsDefaultUseInFutureBudgets: Bool = true { willSet { objectWillChange.send() } }

    // Preferred budgeting period now persists via Workspace (Core Data), not here.

    // Removed: syncCardThemes and syncBudgetPeriod – both are Core Data backed now.

    /// Enable iCloud/CloudKit synchronization for Core Data.
    /// When turned off, dependent sync options are also disabled.
    @AppStorage(AppSettingsKeys.enableCloudSync.rawValue)
    var enableCloudSync: Bool = false {
        willSet { objectWillChange.send() }
        didSet {
            // No dependent toggles
        }
    }

    /// When enabled, Home widget layouts are synced via iCloud key-value storage.
    @AppStorage(AppSettingsKeys.syncHomeWidgetsAcrossDevices.rawValue)
    var syncHomeWidgetsAcrossDevices: Bool = false { willSet { objectWillChange.send() } }

    // MARK: - Init
    init() {
        UserDefaults.standard.register(defaults: [
            AppSettingsKeys.confirmBeforeDelete.rawValue: true,
            AppSettingsKeys.calendarHorizontal.rawValue: true,
            AppSettingsKeys.presetsDefaultUseInFutureBudgets.rawValue: true,
            AppSettingsKeys.budgetPeriod.rawValue: BudgetPeriod.monthly.rawValue,
            AppSettingsKeys.enableCloudSync.rawValue: false,
            AppSettingsKeys.syncHomeWidgetsAcrossDevices.rawValue: false,
            AppSettingsKeys.enableDailyReminder.rawValue: false,
            AppSettingsKeys.enablePlannedIncomeReminder.rawValue: false,
            AppSettingsKeys.notificationReminderTimeMinutes.rawValue: 20 * 60
        ])
    }
}

// MARK: - Cross-Platform Colors
/// iOS has `UIColor.secondarySystemBackground/tertiarySystemBackground`; macOS does not.
/// These helpers map to sensible AppKit equivalents so our views compile everywhere.
// MARK: - SettingsIcon
/// Rounded square icon that mimics iOS Settings iconography.
/// - Parameters:
///   - systemName: SFSymbol name (e.g., "gearshape").
///   - tint: Foreground tint; defaults to primary.
struct SettingsIcon: View {
    let systemName: String
    var tint: Color = .primary
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ScaledMetric(relativeTo: .body) private var compactDimension: CGFloat = 40
    @ScaledMetric(relativeTo: .body) private var regularDimension: CGFloat = 48
    @ScaledMetric(relativeTo: .body) private var compactCornerRadius: CGFloat = 14
    @ScaledMetric(relativeTo: .body) private var regularCornerRadius: CGFloat = 16

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: iconCornerRadius, style: .continuous)
                .fill(themeManager.selectedTheme.secondaryBackground)
            Image(systemName: systemName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(tint)
        }
        .frame(width: iconDimension, height: iconDimension)
        .accessibilityHidden(true)
    }

    private var isCompact: Bool {
        #if os(iOS)
        horizontalSizeClass == .compact
        #else
        false
        #endif
    }

    private var iconDimension: CGFloat { isCompact ? compactDimension : regularDimension }
    private var iconCornerRadius: CGFloat { isCompact ? compactCornerRadius : regularCornerRadius }
}

// MARK: - SettingsCard
/// A card with a header (icon, title, subtitle) and a content area for rows.
/// Use for both the hero card and smaller grouped cards.
/// - Parameters:
///   - iconSystemName: SFSymbol for the header icon.
///   - title: Primary title.
///   - subtitle: Secondary descriptive text; keep concise.
///   - content: Row content; `SettingsRow`, `Toggle`, `NavigationLink`, etc.
struct SettingsCard<Content: View>: View {
    let iconSystemName: String
    let title: String
    let subtitle: String
    @ViewBuilder var content: Content
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.platformCapabilities) private var capabilities

    var body: some View {
        if capabilities.supportsOS26Translucency,
           #available(iOS 26.0, macOS 26.0, macCatalyst 26.0, *) {
            modernCard()
        } else {
            legacyCard()
        }
    }

    private var isCompact: Bool {
        #if os(iOS)
        horizontalSizeClass == .compact
        #else
        false
        #endif
    }

    private var innerCornerRadius: CGFloat { 14 }
    private var cardPadding: CGFloat { isCompact ? 10 : 16 }
    private var headerSpacing: CGFloat { isCompact ? 6 : 12 }
    private var outerCornerRadius: CGFloat { isCompact ? 14 : 20 }

    @ViewBuilder
    private func legacyCard() -> some View {
        VStack(alignment: .leading, spacing: headerSpacing) {
            cardHeader
            rowsContainer
                .background(
                    RoundedRectangle(cornerRadius: innerCornerRadius, style: .continuous)
                        .fill(themeManager.selectedTheme.secondaryBackground)
                )
        }
        .padding(cardPadding)
        .background(
            RoundedRectangle(cornerRadius: outerCornerRadius, style: .continuous)
                .fill(themeManager.selectedTheme.tertiaryBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: outerCornerRadius, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06))
        )
    }

    @available(iOS 26.0, macOS 26.0, macCatalyst 26.0, *)
    @ViewBuilder
    private func modernCard() -> some View {
        let outerShape = RoundedRectangle(cornerRadius: outerCornerRadius, style: .continuous)
        let innerShape = RoundedRectangle(cornerRadius: innerCornerRadius, style: .continuous)

        GlassEffectContainer {
            VStack(alignment: .leading, spacing: headerSpacing) {
                cardHeader
                rowsContainer
                    .glassEffect(.regular, in: innerShape)
            }
            .padding(cardPadding)
            .glassEffect(.regular, in: outerShape)
        }
    }

    @ViewBuilder
    private var cardHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            SettingsIcon(systemName: iconSystemName)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.title3).fontWeight(.semibold)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var rowsContainer: some View {
        VStack(spacing: 0) {
            content
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - SettingsRow
/// A simple row with a left label and optional trailing content (toggle, value label, chevron).
/// Use to keep card internals consistent.
/// - Parameters:
///   - title: Row label.
///   - detail: Optional trailing text if not using a custom trailing view.
///   - trailing: Optional custom trailing view (e.g., Toggle).
struct SettingsRow<Trailing: View>: View {
    let title: String
    var detail: String? = nil
    var showsTopDivider: Bool = true
    @ViewBuilder var trailing: Trailing
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ScaledMetric(relativeTo: .body) private var compactRowPadding: CGFloat = 10
    @ScaledMetric(relativeTo: .body) private var regularRowPadding: CGFloat = 14
    @ScaledMetric(relativeTo: .body) private var compactRowMinHeight: CGFloat = 40
    @ScaledMetric(relativeTo: .body) private var regularRowMinHeight: CGFloat = 48

    init(title: String, detail: String? = nil, showsTopDivider: Bool = true, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.detail = detail
        self.showsTopDivider = showsTopDivider
        self.trailing = trailing()
    }

    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundStyle(themeManager.selectedTheme.primaryTextColor(for: colorScheme))
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            if let detail {
                Text(detail)
                    .foregroundStyle(.secondary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            trailing
        }
        .padding(.horizontal, rowHorizontalPadding)
        .frame(maxWidth: .infinity, minHeight: rowMinHeight)
        .contentShape(Rectangle())
        .overlay(alignment: .top) {
            if showsTopDivider {
                Rectangle()
                    .fill(Color.primary.opacity(0.06))
                    .frame(height: 0.5)
                    .offset(y: -0.25)
            }
        }
    }

    private var isCompact: Bool {
        #if os(iOS)
        horizontalSizeClass == .compact
        #else
        false
        #endif
    }

    private var rowHorizontalPadding: CGFloat { isCompact ? compactRowPadding : regularRowPadding }
    private var rowMinHeight: CGFloat { isCompact ? compactRowMinHeight : regularRowMinHeight }
}
