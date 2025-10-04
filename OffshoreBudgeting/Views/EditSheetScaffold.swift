//
//  EditSheetScaffold.swift
//  SoFar
//
//  A reusable, cross-platform scaffold for editing sheets.
//  Standardizes:
//  - Navigation title
//  - Cancel / Save buttons (toolbar placements map correctly on iOS & macOS)
//  - Presentation detents & drag indicator on iOS/iPadOS
//  - Form container with consistent spacing
//

import SwiftUI
import UIKit

// MARK: - UBPresentationDetent (compat wrapper)
// On iOS 16+ / macOS 13+, this bridges to SwiftUI.PresentationDetent.
// On earlier OS versions, it’s a placeholder so the view still compiles;
// detents are simply ignored.
enum UBPresentationDetent: Equatable, Hashable {
    case medium
    case large
    case fraction(Double)

    @available(iOS 16.0, *)
    var systemDetent: PresentationDetent {
        switch self {
        case .medium: return .medium
        case .large: return .large
        case .fraction(let v): return .fraction(v)
        }
    }
}

// MARK: - EditSheetScaffold
struct EditSheetScaffold<Content: View>: View {

    // MARK: Inputs
    let title: String
    // Use compatibility detents so the type is available on older OSes.
    let detents: [UBPresentationDetent]
    let saveButtonTitle: String
    let cancelButtonTitle: String
    let isSaveEnabled: Bool
    var onCancel: (() -> Void)?
    var onSave: () -> Bool
    @ViewBuilder var content: Content

    // MARK: Environment
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager

    // Selection state for detents (compat type)
    @State private var detentSelection: UBPresentationDetent

    // MARK: Init
    init(
        title: String,
        // Default detents mapped to compat type
        detents: [UBPresentationDetent] = [.medium, .large],
        initialDetent: UBPresentationDetent? = nil,
        saveButtonTitle: String = "Save",
        cancelButtonTitle: String = "Cancel",
        isSaveEnabled: Bool = true,
        onCancel: (() -> Void)? = nil,
        onSave: @escaping () -> Bool,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.detents = detents
        self.saveButtonTitle = saveButtonTitle
        self.cancelButtonTitle = cancelButtonTitle
        self.isSaveEnabled = isSaveEnabled
        self.onCancel = onCancel
        self.onSave = onSave
        self.content = content()
        _detentSelection = State(initialValue: initialDetent ?? detents.last ?? .medium)
    }

    // MARK: body
    var body: some View {
        navigationContainer {
            formContent
                .navigationTitle(title)
                .toolbar {
                    // Cancel
                    ToolbarItem(placement: .cancellationAction) {
                        Button(cancelButtonTitle) {
                            onCancel?()
                            dismiss()
                        }
                        .tint(themeManager.selectedTheme.resolvedTint)
                    }
                    // Save
                    ToolbarItem(placement: .confirmationAction) {
                        ToolbarCTAButton(
                            title: saveButtonTitle,
                            isEnabled: isSaveEnabled
                        ) {
                            if onSave() { dismiss() }
                        }
                    }
                }
        }
        .ub_navigationBackground(
            theme: themeManager.selectedTheme,
            configuration: themeManager.glassConfiguration
        )
        .accentColor(themeManager.selectedTheme.resolvedTint)
        .tint(themeManager.selectedTheme.resolvedTint)
        .ub_surfaceBackground(
            themeManager.selectedTheme,
            configuration: themeManager.glassConfiguration
        )
        // MARK: Standard sheet behavior (platform-aware)
        .applyDetentsIfAvailable(detents: detents, selection: detentSelectionBinding)
    }

    // MARK: - Subviews

    // Navigation container: NavigationStack on iOS 16+/macOS 13+, else NavigationView
    @ViewBuilder
    private func navigationContainer<Inner: View>(@ViewBuilder content: () -> Inner) -> some View {
        if #available(iOS 16.0, macCatalyst 16.0, *) {
            NavigationStack { content() }
        } else {
            NavigationView { content() }
        }
    }

    // The form body with shared styling
    @ViewBuilder
    private var formContent: some View {
        if #available(iOS 16.0, macCatalyst 16.0, *) {
            Form { content }
                .scrollContentBackground(.hidden)
                .listRowBackground(rowBackground)
                .ub_surfaceBackground(
                    themeManager.selectedTheme,
                    configuration: themeManager.glassConfiguration
                )
                .ub_formStyleGrouped()
                .ub_hideScrollIndicators()
                .multilineTextAlignment(.leading)
        } else {
            Form { content }
                .listRowBackground(rowBackground)
                .ub_surfaceBackground(
                    themeManager.selectedTheme,
                    configuration: themeManager.glassConfiguration
                )
                .ub_formStyleGrouped()
                .ub_hideScrollIndicators()
                .multilineTextAlignment(.leading)
        }
    }

    // MARK: Row Background
    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(themeManager.selectedTheme.secondaryBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(separatorColor, lineWidth: 1)
            )
    }

    private var separatorColor: Color {
        return Color(uiColor: .separator)
    }

    // MARK: Detent selection binding (iOS only)
    private var detentSelectionBinding: Binding<UBPresentationDetent>? { $detentSelection }
}

// MARK: - ToolbarCTAButton
@MainActor
private struct ToolbarCTAButton: View {
    @Environment(\.platformCapabilities) private var capabilities
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    private let title: String
    private let role: ButtonRole?
    private let isEnabled: Bool
    private let overrideTint: Color?
    private let accessibilityIdentifier: String?
    private let action: () -> Void

    init(
        title: String,
        role: ButtonRole? = nil,
        isEnabled: Bool = true,
        tint: Color? = nil,
        accessibilityIdentifier: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.role = role
        self.isEnabled = isEnabled
        self.overrideTint = tint
        self.accessibilityIdentifier = accessibilityIdentifier
        self.action = action
    }

    @ViewBuilder
    var body: some View {
        if capabilities.supportsOS26Translucency, #available(iOS 26.0, macOS 26.0, macCatalyst 26.0, *) {
#if DEBUG && LIQUID_GLASS_QA
            capabilities.qaLogLiquidGlassDecision(component: "ToolbarCTAButton", path: "glass")
#endif
            baseButton(glassPath: true)
                .buttonStyle(.glass)
                .buttonBorderShape(.capsule)
                .tint(glassTint)
                .glassEffect(
                    .regular.tint(glassTint).interactive(),
                    in: Capsule(style: .continuous)
                )
        } else {
#if DEBUG && LIQUID_GLASS_QA
            capabilities.qaLogLiquidGlassDecision(component: "ToolbarCTAButton", path: "legacy")
#endif
            baseButton(glassPath: false)
                .buttonStyle(
                    TranslucentButtonStyle(
                        tint: resolvedTint,
                        metrics: .rootActionLabel,
                        appearance: .tinted
                    )
                )
                .tint(resolvedTint)
        }
    }

    @ViewBuilder
    private func baseButton(glassPath: Bool) -> some View {
        Button(role: role) {
            action()
        } label: {
            labelContent(glassPath: glassPath)
        }
        .disabled(!isEnabled)
        .optionalAccessibilityIdentifier(accessibilityIdentifier)
    }

    @ViewBuilder
    private func labelContent(glassPath: Bool) -> some View {
        let base = Text(title)
            .font(labelFont)
            .padding(.horizontal, labelHorizontalPadding)
            .padding(.vertical, labelVerticalPadding)
            .frame(width: labelWidth, height: labelHeight)
            .contentShape(Capsule(style: .continuous))
            .lineLimit(1)

        if glassPath {
            base.foregroundStyle(glassLabelForeground)
        } else {
            base
        }
    }

    private var labelFont: Font {
        Self.labelMetrics.font ?? .system(size: 17, weight: .semibold, design: .rounded)
    }

    private var labelWidth: CGFloat? { Self.labelMetrics.width }

    private var labelHeight: CGFloat {
        Self.labelMetrics.height ?? 44
    }

    private var labelHorizontalPadding: CGFloat { Self.labelMetrics.horizontalPadding }

    private var labelVerticalPadding: CGFloat { Self.labelMetrics.verticalPadding }

    private var resolvedTint: Color {
        overrideTint ?? themeManager.selectedTheme.resolvedTint
    }

    private var glassTint: Color {
        overrideTint ?? themeManager.selectedTheme.glassPalette.accent
    }

    private var glassLabelForeground: Color {
        colorScheme == .light ? .black : .primary
    }

    private static let labelMetrics = TranslucentButtonStyle.Metrics.rootActionLabel
}

// MARK: - Detents application helper
extension View {
    // Applies presentationDetents and drag indicator only on iOS 16+.
    func applyDetentsIfAvailable(
        detents: [UBPresentationDetent],
        selection: Binding<UBPresentationDetent>?
    ) -> some View {
        if #available(iOS 16.0, *) {
            // Map compat detents to system detents
            let systemDetents = Set(detents.map { $0.systemDetent })
            if let selection {
                // Bridge the selection binding by mapping to/from system detents
                let bridged = Binding<PresentationDetent>(
                    get: { selection.wrappedValue.systemDetent },
                    set: { newValue in
                        // Reverse-map the system detent back to UBPresentationDetent
                        let mapped: UBPresentationDetent
                        switch newValue {
                        case .medium: mapped = .medium
                        case .large: mapped = .large
                        default:
                            // Fraction detents aren’t equatable by value; default to medium.
                            mapped = .medium
                        }
                        selection.wrappedValue = mapped
                    }
                )
                return AnyView(
                    self
                        .presentationDetents(systemDetents, selection: bridged)
                        .presentationDragIndicator(.visible)
                )
            } else {
                return AnyView(
                    self
                        .presentationDetents(systemDetents)
                        .presentationDragIndicator(.visible)
                )
            }
        } else {
            return AnyView(self)
        }
    }
}
