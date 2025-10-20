import SwiftUI
import Combine

// MARK: - OnboardingView2
struct OnboardingView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.platformCapabilities) private var capabilities
    @AppStorage("didCompleteOnboarding") private var didCompleteOnboarding: Bool = false
    @AppStorage(AppSettingsKeys.enableCloudSync.rawValue) private var enableCloudSync: Bool = false
    @AppStorage(AppSettingsKeys.syncCardThemes.rawValue) private var syncCardThemes: Bool = false
    @AppStorage(AppSettingsKeys.syncBudgetPeriod.rawValue) private var syncBudgetPeriod: Bool = false

    enum Step { case welcome, categories, cards, presets, loading }
    @State private var step: Step = .welcome

    var body: some View {
        ZStack {
            themeManager.selectedTheme.background
                .overlay(Color.black.opacity(capabilities.supportsOS26Translucency ? 0.04 : 0.06))
                .ignoresSafeArea()

            switch step {
            case .welcome:
                WelcomeStep2 { step = .categories }
            case .categories:
                CategoriesStep2(
                    onNext: { step = .cards },
                    onBack: { step = .welcome }
                )
            case .cards:
                CardsStep2(
                    onNext: { step = .presets },
                    onBack: { step = .categories }
                )
            case .presets:
                PresetsStep2(
                    onNext: { step = .loading },
                    onBack: { step = .cards }
                )
            case .loading:
                LoadingStep2 { didCompleteOnboarding = true }
            }
        }
        .animation(.easeInOut, value: step)
        .transition(.opacity)
        .onboardingPresentation() // mark hierarchy for onboarding-specific styling
        .onChange(of: enableCloudSync) { newValue in
            if newValue {
                if !syncCardThemes { syncCardThemes = true }
                if !syncBudgetPeriod { syncBudgetPeriod = true }
            }
            Task { @MainActor in
                await CoreDataService.shared.applyCloudSyncPreferenceChange(enableSync: newValue)
            }
        }
    }
}

// MARK: - Steps
private struct WelcomeStep2: View {
    let onNext: () -> Void
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            VStack(spacing: 8) {
                Text("Welcome to Offshore Budgeting").font(.largeTitle.bold())
                Text("Let's set up your budgeting workspace.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: 520)
            Spacer()
            OnboardingButtonsRow2(back: nil, nextTitle: "Get Started", onBack: {}, onNext: onNext)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct CategoriesStep2: View {
    let onNext: () -> Void
    let onBack: () -> Void
    var body: some View {
        navigationContainer {
            ZStack(alignment: .bottom) {
                ExpenseCategoryManagerView()
                OnboardingButtonsRow2(back: "Back", nextTitle: "Done", onBack: onBack, onNext: onNext)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }
        }
    }
}

private struct CardsStep2: View {
    let onNext: () -> Void
    let onBack: () -> Void
    var body: some View {
        navigationContainer {
            ZStack(alignment: .bottom) {
                CardsView()
                OnboardingButtonsRow2(back: "Back", nextTitle: "Done", onBack: onBack, onNext: onNext)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }
        }
    }
}

private struct PresetsStep2: View {
    let onNext: () -> Void
    let onBack: () -> Void
    var body: some View {
        navigationContainer {
            ZStack(alignment: .bottom) {
                PresetsView()
                OnboardingButtonsRow2(back: "Back", nextTitle: "Done", onBack: onBack, onNext: onNext)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }
        }
    }
}

private struct LoadingStep2: View {
    let onFinish: () -> Void
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Preparing your workspace…").foregroundStyle(.secondary)
        }
        .task { try? await Task.sleep(nanoseconds: 1_000_000_000); onFinish() }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Buttons Row
private struct OnboardingButtonsRow2: View {
    let back: String?
    let nextTitle: String
    let onBack: () -> Void
    let onNext: () -> Void
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: 12) {
            if let back { secondaryButton(title: back, action: onBack) }
            primaryButton(title: nextTitle, action: onNext)
        }
        .frame(maxWidth: 560)
    }

    // iOS26: glass capsule; legacy: rounded rectangle
    @ViewBuilder
    private func primaryButton(title: String, action: @escaping () -> Void) -> some View {
        let tint = themeManager.selectedTheme.resolvedTint
        if #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *) {
            Button(action: action) {
                Text(title).font(.headline).frame(maxWidth: .infinity, minHeight: 44)
                    .glassEffect(.regular.tint(.none))
            }
                .buttonStyle(.plain)
                .buttonBorderShape(.capsule)
                .frame(minHeight: 44)
        } else {
            Button(action: action) {
                Text(title).font(.headline).frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.plain)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .frame(minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(tint.opacity(0.16))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(tint.opacity(0.35), lineWidth: 1)
            )
        }
    }

    @ViewBuilder
    private func secondaryButton(title: String, action: @escaping () -> Void) -> some View {
        let tint = themeManager.selectedTheme.resolvedTint
        if #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *) {
            Button(action: action) {
                Text(title).font(.headline).frame(maxWidth: .infinity, minHeight: 44)
                    .glassEffect(.regular.tint(.gray.opacity(0.5)))
            }
                .buttonStyle(.plain)
                .buttonBorderShape(.capsule)
                .frame(minHeight: 44)
        } else {
            Button(action: action) {
                Text(title).font(.headline).frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.plain)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .frame(minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(tint.opacity(0.35), lineWidth: 1)
            )
        }
    }
}

// MARK: - Nav container (compat)
@ViewBuilder
private func navigationContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    if #available(iOS 16.0, macCatalyst 16.0, *) {
        NavigationStack { content() }
    } else {
        NavigationView { content() }.navigationViewStyle(.stack)
    }
}
