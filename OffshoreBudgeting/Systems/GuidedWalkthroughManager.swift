import SwiftUI

// MARK: - Overlay Model
/// Describes a walkthrough overlay for a top-level destination.
struct Overlay: Identifiable, Equatable {
    let id: GuidedWalkthroughManager.Screen
    let title: String
    let message: String
    let actionTitle: String
}

// MARK: - Hint Model
/// Lightweight data model for contextual hint bubbles.
struct HintBubble: Identifiable, Equatable {
    let id: GuidedWalkthroughManager.Hint
    let iconSystemName: String
    let message: String
}

// MARK: - GuidedWalkthroughManager
@MainActor
final class GuidedWalkthroughManager: ObservableObject {

    // MARK: Destinations & Hints
    enum Screen: String, CaseIterable, Identifiable {
        case home
        case income
        case cards
        case presets
        case settings
        case cardDetail

        var id: String { rawValue }
    }

    enum Hint: String, CaseIterable, Identifiable, Hashable {
        case homeThreeDots
        case homeCalendar
        case homeAddExpense
        case incomeAdd
        case incomeEdit
        case cardsAdd
        case cardsTile
        case cardDetailEdit
        case cardDetailSearch
        case cardDetailAddExpense
        case presetsNextDate
        case presetsAssignments
        case settingsGeneral
        case settingsCategories
        case settingsData

        var id: String { rawValue }
    }

    // MARK: Overlay Storage
    @AppStorage("guided.overlay.home")
    private var homeOverlaySeen: Bool = false { willSet { objectWillChange.send() } }
    @AppStorage("guided.overlay.income")
    private var incomeOverlaySeen: Bool = false { willSet { objectWillChange.send() } }
    @AppStorage("guided.overlay.cards")
    private var cardsOverlaySeen: Bool = false { willSet { objectWillChange.send() } }
    @AppStorage("guided.overlay.presets")
    private var presetsOverlaySeen: Bool = false { willSet { objectWillChange.send() } }
    @AppStorage("guided.overlay.settings")
    private var settingsOverlaySeen: Bool = false { willSet { objectWillChange.send() } }

    // MARK: Hint Storage
    @AppStorage("guided.hint.home.threeDots")
    private var homeThreeDotsSeen: Bool = false { willSet { objectWillChange.send() } }
    @AppStorage("guided.hint.home.calendar")
    private var homeCalendarSeen: Bool = false { willSet { objectWillChange.send() } }
    @AppStorage("guided.hint.home.add")
    private var homeAddSeen: Bool = false { willSet { objectWillChange.send() } }
    @AppStorage("guided.hint.income.add")
    private var incomeAddSeen: Bool = false { willSet { objectWillChange.send() } }
    @AppStorage("guided.hint.income.edit")
    private var incomeEditSeen: Bool = false { willSet { objectWillChange.send() } }
    @AppStorage("guided.hint.cards.add")
    private var cardsAddSeen: Bool = false { willSet { objectWillChange.send() } }
    @AppStorage("guided.hint.cards.tile")
    private var cardsTileSeen: Bool = false { willSet { objectWillChange.send() } }
    @AppStorage("guided.hint.cardDetail.edit")
    private var cardDetailEditSeen: Bool = false { willSet { objectWillChange.send() } }
    @AppStorage("guided.hint.cardDetail.search")
    private var cardDetailSearchSeen: Bool = false { willSet { objectWillChange.send() } }
    @AppStorage("guided.hint.cardDetail.add")
    private var cardDetailAddSeen: Bool = false { willSet { objectWillChange.send() } }
    @AppStorage("guided.hint.presets.nextDate")
    private var presetsNextDateSeen: Bool = false { willSet { objectWillChange.send() } }
    @AppStorage("guided.hint.presets.assignments")
    private var presetsAssignmentsSeen: Bool = false { willSet { objectWillChange.send() } }
    @AppStorage("guided.hint.settings.general")
    private var settingsGeneralSeen: Bool = false { willSet { objectWillChange.send() } }
    @AppStorage("guided.hint.settings.categories")
    private var settingsCategoriesSeen: Bool = false { willSet { objectWillChange.send() } }
    @AppStorage("guided.hint.settings.data")
    private var settingsDataSeen: Bool = false { willSet { objectWillChange.send() } }

    @AppStorage("didCompleteOnboarding")
    private var didCompleteOnboarding: Bool = false { willSet { objectWillChange.send() } }

    // MARK: Content Catalog
    private let overlaysByScreen: [Screen: Overlay]
    private let hintsByScreen: [Screen: [HintBubble]]

    init() {
        overlaysByScreen = [
            .home: Overlay(
                id: .home,
                title: "Home Overview",
                message: "Welcome to your budget hub! Use these controls to switch periods, add expenses, and manage budgets.",
                actionTitle: "Show hints"
            ),
            .income: Overlay(
                id: .income,
                title: "Income Overview",
                message: "Track planned versus actual income here. Browse days to compare and adjust entries.",
                actionTitle: "Show hints"
            ),
            .cards: Overlay(
                id: .cards,
                title: "Cards Overview",
                message: "Cards act like spending envelopes. Add cards and tap one to review its activity.",
                actionTitle: "Show hints"
            ),
            .presets: Overlay(
                id: .presets,
                title: "Presets Overview",
                message: "Preset expenses speed up budget creation. Add items once and reuse them anytime.",
                actionTitle: "Show hints"
            ),
            .settings: Overlay(
                id: .settings,
                title: "Settings Overview",
                message: "Adjust Offshore to fit your workflow, manage data, and replay onboarding here.",
                actionTitle: "Show hints"
            )
        ]

        hintsByScreen = [
            .home: [
                HintBubble(
                    id: .homeThreeDots,
                    iconSystemName: "ellipsis",
                    message: "Open tools to edit the budget, manage cards, or presets."
                ),
                HintBubble(
                    id: .homeCalendar,
                    iconSystemName: "calendar",
                    message: "Jump between budget periods or pick a custom range."
                ),
                HintBubble(
                    id: .homeAddExpense,
                    iconSystemName: "plus",
                    message: "Add planned or variable expenses for this budget."
                )
            ],
            .income: [
                HintBubble(
                    id: .incomeAdd,
                    iconSystemName: "plus",
                    message: "Add a new income entry for the selected date."
                ),
                HintBubble(
                    id: .incomeEdit,
                    iconSystemName: "pencil",
                    message: "Edit this income entry."
                )
            ],
            .cards: [
                HintBubble(
                    id: .cardsAdd,
                    iconSystemName: "plus",
                    message: "Create a new spending card."
                ),
                HintBubble(
                    id: .cardsTile,
                    iconSystemName: "creditcard",
                    message: "Open card details to see category totals and expenses."
                )
            ],
            .cardDetail: [
                HintBubble(
                    id: .cardDetailEdit,
                    iconSystemName: "pencil",
                    message: "Rename or restyle this card."
                ),
                HintBubble(
                    id: .cardDetailSearch,
                    iconSystemName: "magnifyingglass",
                    message: "Filter expenses by keyword or category."
                ),
                HintBubble(
                    id: .cardDetailAddExpense,
                    iconSystemName: "plus",
                    message: "Add a variable expense to this card."
                )
            ],
            .presets: [
                HintBubble(
                    id: .presetsNextDate,
                    iconSystemName: "calendar.badge.clock",
                    message: "Shows the scheduled date applied when this preset is used."
                ),
                HintBubble(
                    id: .presetsAssignments,
                    iconSystemName: "tray.fill",
                    message: "See which budgets currently include this preset."
                )
            ],
            .settings: [
                HintBubble(
                    id: .settingsGeneral,
                    iconSystemName: "slider.horizontal.3",
                    message: "Change default budget period and confirmation prompts."
                ),
                HintBubble(
                    id: .settingsCategories,
                    iconSystemName: "tag",
                    message: "Manage the categories used for variable expenses."
                ),
                HintBubble(
                    id: .settingsData,
                    iconSystemName: "icloud",
                    message: "Handle sync preferences or clear stored data."
                )
            ]
        ]
    }

    // MARK: Overlay API
    func overlay(for screen: Screen) -> Overlay? {
        overlaysByScreen[screen]
    }

    func shouldShowOverlay(for screen: Screen) -> Bool {
        guard overlaysByScreen[screen] != nil else { return false }
        return !overlaySeen(for: screen)
    }

    func markOverlaySeen(for screen: Screen) {
        setOverlay(seen: true, for: screen)
    }

    // MARK: Hint API
    func hints(for screen: Screen) -> [HintBubble] {
        hintsByScreen[screen] ?? []
    }

    func hint(for identifier: Hint) -> HintBubble? {
        hintsByScreen.values.flatMap { $0 }.first(where: { $0.id == identifier })
    }

    func shouldShowHint(_ hint: Hint) -> Bool {
        guard self.hint(for: hint) != nil else { return false }
        return !hintSeen(hint)
    }

    func markHintSeen(_ hint: Hint) {
        if !hintSeen(hint) {
            setHint(hint, seen: true)
        }
    }

    func resetAll() {
        Screen.allCases.forEach { screen in
            setOverlay(seen: false, for: screen)
        }

        Hint.allCases.forEach { hint in
            setHint(hint, seen: false)
        }

        didCompleteOnboarding = false
    }

    // MARK: Overlay Persistence helpers
    private func overlaySeen(for screen: Screen) -> Bool {
        switch screen {
        case .home: return homeOverlaySeen
        case .income: return incomeOverlaySeen
        case .cards: return cardsOverlaySeen
        case .presets: return presetsOverlaySeen
        case .settings: return settingsOverlaySeen
        case .cardDetail: return true
        }
    }

    private func setOverlay(seen: Bool, for screen: Screen) {
        switch screen {
        case .home: homeOverlaySeen = seen
        case .income: incomeOverlaySeen = seen
        case .cards: cardsOverlaySeen = seen
        case .presets: presetsOverlaySeen = seen
        case .settings: settingsOverlaySeen = seen
        case .cardDetail: break
        }
    }

    // MARK: Hint Persistence helpers
    private func hintSeen(_ hint: Hint) -> Bool {
        switch hint {
        case .homeThreeDots: return homeThreeDotsSeen
        case .homeCalendar: return homeCalendarSeen
        case .homeAddExpense: return homeAddSeen
        case .incomeAdd: return incomeAddSeen
        case .incomeEdit: return incomeEditSeen
        case .cardsAdd: return cardsAddSeen
        case .cardsTile: return cardsTileSeen
        case .cardDetailEdit: return cardDetailEditSeen
        case .cardDetailSearch: return cardDetailSearchSeen
        case .cardDetailAddExpense: return cardDetailAddSeen
        case .presetsNextDate: return presetsNextDateSeen
        case .presetsAssignments: return presetsAssignmentsSeen
        case .settingsGeneral: return settingsGeneralSeen
        case .settingsCategories: return settingsCategoriesSeen
        case .settingsData: return settingsDataSeen
        }
    }

    private func setHint(_ hint: Hint, seen: Bool) {
        switch hint {
        case .homeThreeDots: homeThreeDotsSeen = seen
        case .homeCalendar: homeCalendarSeen = seen
        case .homeAddExpense: homeAddSeen = seen
        case .incomeAdd: incomeAddSeen = seen
        case .incomeEdit: incomeEditSeen = seen
        case .cardsAdd: cardsAddSeen = seen
        case .cardsTile: cardsTileSeen = seen
        case .cardDetailEdit: cardDetailEditSeen = seen
        case .cardDetailSearch: cardDetailSearchSeen = seen
        case .cardDetailAddExpense: cardDetailAddSeen = seen
        case .presetsNextDate: presetsNextDateSeen = seen
        case .presetsAssignments: presetsAssignmentsSeen = seen
        case .settingsGeneral: settingsGeneralSeen = seen
        case .settingsCategories: settingsCategoriesSeen = seen
        case .settingsData: settingsDataSeen = seen
        }
    }
}

// MARK: - GuidedOverlayView
struct GuidedOverlayView: View {
    let overlay: Overlay
    let onDismiss: () -> Void
    let nextAction: () -> Void

    @Environment(\.platformCapabilities) private var capabilities

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .transition(.opacity)

            VStack(spacing: 20) {
                Text(overlay.title)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)

                Text(overlay.message)
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)

                actionButton
            }
            .padding(28)
            .frame(maxWidth: 420)
            .background(background)
            .padding(.horizontal, 24)
            .transition(.scale.combined(with: .opacity))
        }
    }

    private func dismiss() {
        withAnimation(.easeInOut(duration: 0.3)) {
            onDismiss()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            nextAction()
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        if capabilities.supportsOS26Translucency,
           #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *) {
            GlassEffectContainer {
                Button(action: dismiss) {
                    Label(overlay.actionTitle, systemImage: "sparkles")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 28)
                        .glassEffect(.regular.tint(.clear).interactive(true))
                }
                .buttonStyle(.plain)
                .buttonBorderShape(.capsule)
            }
        } else {
            Button(action: dismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color.primary.opacity(0.15))
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
    }

    @ViewBuilder
    private var background: some View {
        if capabilities.supportsOS26Translucency,
           #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.clear)
                .glassEffect(.regular.tint(.clear).interactive(true))
        } else {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.25), radius: 18, x: 0, y: 10)
        }
    }
}

// MARK: - HintBubbleView
struct HintBubbleView: View {
    let hint: HintBubble

    @Environment(\.platformCapabilities) private var capabilities

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: hint.iconSystemName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)
                .padding(.top, 2)

            Text(hint.message)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .multilineTextAlignment(.leading)
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(bubbleBackground)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .shadow(color: Color.black.opacity(0.18), radius: 8, x: 0, y: 4)
        .allowsHitTesting(false)
        .transition(.opacity)
    }

    @ViewBuilder
    private var bubbleBackground: some View {
        if capabilities.supportsOS26Translucency,
           #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.clear)
                .glassEffect(.regular.tint(.clear).interactive(true))
        } else {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.black.opacity(0.75))
        }
    }
}
