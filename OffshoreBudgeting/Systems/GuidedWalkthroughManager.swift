import SwiftUI

// MARK: - Tips & Hints Models
enum TipsScreen: String, CaseIterable, Identifiable {
    case home
    case budgets
    case income
    case cards
    case cardDetail
    case categories
    case presets

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .budgets: return "Budgets"
        case .income: return "Income"
        case .cards: return "Cards"
        case .cardDetail: return "Card Details"
        case .categories: return "Categories"
        case .presets: return "Presets"
        }
    }
}

enum TipsKind: String {
    case walkthrough
    case whatsNew
}

struct TipsItem: Identifiable, Equatable {
    let id = UUID()
    let symbolName: String
    let title: String
    let detail: String
}

struct TipsContent: Equatable {
    let title: String
    let items: [TipsItem]
    let actionTitle: String
}

// MARK: - Tips Catalog
enum TipsCatalog {
    static func content(for screen: TipsScreen, kind: TipsKind = .walkthrough, versionToken: String? = nil) -> TipsContent? {
        switch kind {
        case .walkthrough:
            return walkthroughContent(for: screen)
        case .whatsNew:
            return whatsNewContent(for: screen, versionToken: versionToken)
        }
    }

    private static func walkthroughContent(for screen: TipsScreen) -> TipsContent? {
        switch screen {
        case .home:
            return TipsContent(
                title: "Welcome to Home",
                items: [
                    TipsItem(
                        symbolName: "house.fill",
                        title: "Landing Page",
                        detail: "Welcome to your budget dashboard. This is the page you will see each time you open the app."
                    ),
                    TipsItem(
                        symbolName: "widget.small",
                        title: "Widgets",
                        detail: #"Tap "Edit" to pin, reorder, or remove widgets so the view fits you."#
                    )
                ],
                actionTitle: "Continue"
            )
        case .budgets:
            return TipsContent(
                title: "Budgets Overview",
                items: [
                    TipsItem(
                        symbolName: "chart.pie.fill",
                        title: "Budgets",
                        detail: "Create, view, edit, or delete budgets here."
                    ),
                    TipsItem(
                        symbolName: "list.triangle",
                        title: "View & Sort",
                        detail: "Active = happening now, Upcoming = starts later, Past = ended."
                    ),
                    TipsItem(
                        symbolName: "magnifyingglass",
                        title: "Search",
                        detail: "Press the magnifying glass to search budgets by title or date."
                    )
                ],
                actionTitle: "Continue"
            )
        case .income:
            return TipsContent(
                title: "Income Overview",
                items: [
                    TipsItem(
                        symbolName: "calendar",
                        title: "Income Calendar",
                        detail: "View income in a calendar to visualize earnings like a timesheet."
                    ),
                    TipsItem(
                        symbolName: "calendar.badge.plus",
                        title: "Planned Income",
                        detail: "Add income you expect but haven’t received yet."
                    ),
                    TipsItem(
                        symbolName: "calendar.badge.checkmark",
                        title: "Actual Income",
                        detail: "Log income you’ve already received."
                    ),
                    TipsItem(
                        symbolName: "calendar.badge.clock",
                        title: "Recurring Income",
                        detail: "Planned and actual income can repeat automatically."
                    )
                ],
                actionTitle: "Continue"
            )
        case .cards:
            return TipsContent(
                title: "Cards Overview",
                items: [
                    TipsItem(
                        symbolName: "creditcard.fill",
                        title: "Cards",
                        detail: "Browse stored cards and open one to filter or add expenses."
                    )
                ],
                actionTitle: "Continue"
            )
        case .cardDetail:
            return TipsContent(
                title: "Card Detail Tips",
                items: [
                    TipsItem(
                        symbolName: "list.bullet.below.rectangle",
                        title: "Detailed Overview",
                        detail: "Review expenses with advanced filtering."
                    ),
                    TipsItem(
                        symbolName: "magnifyingglass",
                        title: "Search for Expenses",
                        detail: "Search by name or date from the top right."
                    ),
                    TipsItem(
                        symbolName: "tag",
                        title: "Categories",
                        detail: "Tap a category to filter, then tap again to clear."
                    )
                ],
                actionTitle: "Continue"
            )
        case .categories:
            return TipsContent(
                title: "Categories Management",
                items: [
                    TipsItem(
                        symbolName: "tag",
                        title: "Categories",
                        detail: "Add categories to track spending. Swipe a row to edit or delete."
                    )
                ],
                actionTitle: "Continue"
            )
        case .presets:
            return TipsContent(
                title: "Presets Overview",
                items: [
                    TipsItem(
                        symbolName: "list.bullet.badge.ellipsis",
                        title: "Presets",
                        detail: "Save planned expenses you expect to reuse in future budgets."
                    ),
                    TipsItem(
                        symbolName: "text.line.first.and.arrowtriangle.forward",
                        title: "Planned Amount",
                        detail: "Enter the minimum or target amount each month."
                    ),
                    TipsItem(
                        symbolName: "text.line.last.and.arrowtriangle.forward",
                        title: "Actual Amount",
                        detail: "Track the real amount to compare planned versus actual."
                    )
                ],
                actionTitle: "Continue"
            )
        }
    }

    // MARK: - What's New Hooks
    /// Provide per-release content here and surface it by calling
    /// `.tipsAndHintsOverlay(for:kind:versionToken:)` with `.whatsNew`.
    private static func whatsNewContent(for screen: TipsScreen, versionToken: String?) -> TipsContent? {
        guard let versionToken else { return nil }
        switch versionToken {
        case "16":
            switch screen {
            case .home:
                let info = Bundle.main.infoDictionary
                let version = info?["CFBundleShortVersionString"] as? String ?? "0"
                let build = info?["CFBundleVersion"] as? String ?? "0"
                return TipsContent(
                    title: "What's New in Offshore Budgeting (\(version).\(build))",
                    items: [
                        TipsItem(
                            symbolName: "sidebar.left",
                            title: "Sidebar Navigation",
                            detail: "Sidebar navigation support for iPad and Mac."
                        ),
                        TipsItem(
                            symbolName: "sparkles",
                            title: "UI Enhancements",
                            detail: "UI enhancements and cohesion across the app."
                        ),
                        TipsItem(
                            symbolName: "widget.small",
                            title: "Widgets",
                            detail: "iOS and macOS widgets for the Home Screen and Desktop."
                        ),
                        TipsItem(
                            symbolName: "calendar",
                            title: "Income Calendar",
                            detail: "Improved landscape calendar sizing so a full month fits on larger displays."
                        ),
                        TipsItem(
                            symbolName: "questionmark.circle",
                            title: "Help Guide",
                            detail: "More in-depth help guide."
                        ),
                        TipsItem(
                            symbolName: "paintpalette",
                            title: "Category Heat Map",
                            detail: "Card Detail now shows a category heat map on the Total Spent row to help visualize spending."
                        ),
                        TipsItem(
                            symbolName: "lightbulb.fill",
                            title: "Post-Onboarding Tips",
                            detail: "Post-onboarding overlays detailing each screen."
                        ),
                        TipsItem(
                            symbolName: "person.3.fill",
                            title: "Workspaces",
                            detail: "Profiles/Workspaces support for keeping budgets separated, for example, Personal and Work."
                        ),
                        TipsItem(
                            symbolName: "bell.badge",
                            title: "Notifications",
                            detail: "Local device notifications to remind you to log expenses and income."
                        )
                    ],
                    actionTitle: "Got It"
                )
            default:
                return nil
            }
        default:
            return nil
        }
    }
}

// MARK: - Tips & Hints Store
struct TipsAndHintsStore {
    static let shared = TipsAndHintsStore()

    private let defaults: UserDefaults
    private let resetTokenKey = AppSettingsKeys.tipsHintsResetToken.rawValue

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func shouldShowTips(for screen: TipsScreen, kind: TipsKind = .walkthrough, versionToken: String? = nil) -> Bool {
        guard TipsCatalog.content(for: screen, kind: kind, versionToken: versionToken) != nil else { return false }
        return !defaults.bool(forKey: seenKey(for: screen, kind: kind, versionToken: versionToken))
    }

    func markSeen(for screen: TipsScreen, kind: TipsKind = .walkthrough, versionToken: String? = nil) {
        defaults.set(true, forKey: seenKey(for: screen, kind: kind, versionToken: versionToken))
    }

    func resetAllTips() {
        defaults.set(UUID().uuidString, forKey: resetTokenKey)
    }

    private func seenKey(for screen: TipsScreen, kind: TipsKind, versionToken: String?) -> String {
        let resolvedVersion = versionToken ?? appVersionToken()
        let resetToken = ensureResetToken()
        return "tips.seen.\(kind.rawValue).\(screen.rawValue).v\(resolvedVersion).r\(resetToken)"
    }

    private func ensureResetToken() -> String {
        if let token = defaults.string(forKey: resetTokenKey) {
            return token
        }
        let token = UUID().uuidString
        defaults.set(token, forKey: resetTokenKey)
        return token
    }

    private func appVersionToken() -> String {
        let info = Bundle.main.infoDictionary
        let shortVersion = info?["CFBundleShortVersionString"] as? String ?? "0"
        let build = info?["CFBundleVersion"] as? String ?? "0"
        return "\(shortVersion).\(build)"
    }
}

// MARK: - Tips & Hints Overlay
struct TipsAndHintsOverlayModifier: ViewModifier {
    let screen: TipsScreen
    var kind: TipsKind = .walkthrough
    var versionToken: String? = nil

    @State private var isPresented = false
    @State private var didCheck = false

    func body(content: Content) -> some View {
        content
            .task { maybeShow() }
            .ub_platformSheet(isPresented: $isPresented, onDismiss: markSeenOnDismiss) {
                if let payload = TipsCatalog.content(for: screen, kind: kind, versionToken: versionToken) {
                    TipsAndHintsSheet(content: payload, onContinue: dismiss)
                }
            }
    }

    private func maybeShow() {
        guard !didCheck else { return }
        didCheck = true
        if TipsAndHintsStore.shared.shouldShowTips(for: screen, kind: kind, versionToken: versionToken) {
            withAnimation(.easeInOut(duration: 0.2)) {
                isPresented = true
            }
        }
    }

    private func dismiss() {
        TipsAndHintsStore.shared.markSeen(for: screen, kind: kind, versionToken: versionToken)
        isPresented = false
    }

    private func markSeenOnDismiss() {
        TipsAndHintsStore.shared.markSeen(for: screen, kind: kind, versionToken: versionToken)
    }
}

extension View {
    func tipsAndHintsOverlay(for screen: TipsScreen, kind: TipsKind = .walkthrough, versionToken: String? = nil) -> some View {
        modifier(TipsAndHintsOverlayModifier(screen: screen, kind: kind, versionToken: versionToken))
    }
}

// MARK: - Tips & Hints Sheet
struct TipsAndHintsSheet: View {
    let content: TipsContent
    let onContinue: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(content.title)
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.leading)
                Spacer()
                closeButton
            }

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(content.items) { item in
                        TipsItemRow(item: item)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            continueButton
        }
        .padding(20)
    }

    @ViewBuilder
    private var continueButton: some View {
        if #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *) {
            Button {
                onContinue()
                dismiss()
            } label: {
                Text(content.actionTitle)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.glassProminent)
            .tint(.blue)
        } else {
            Button {
                onContinue()
                dismiss()
            } label: {
                Text(content.actionTitle)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.blue)
            )
        }
    }

    @ViewBuilder
    private var closeButton: some View {
        Buttons.toolbarIconGlassPreferred("xmark", label: "Close Tips") { dismiss() }
    }
}

private struct TipsItemRow: View {
    let item: TipsItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: item.symbolName)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(Color(.systemRed))
                .frame(width: 28, alignment: .center)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                Text(item.detail)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
