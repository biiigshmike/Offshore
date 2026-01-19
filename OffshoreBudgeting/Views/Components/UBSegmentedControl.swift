import SwiftUI

/// A tap-stable segmented control implemented with plain Buttons.
///
/// - On iOS 26+/macOS 15+/Catalyst 26+: renders as a capsule with Liquid Glass.
/// - On legacy OSes: renders as a rounded-rect “pill” surface (non-glass).
///
/// This intentionally avoids `.pickerStyle(.segmented)` because that path has shown
/// occasional canceled taps when embedded in scrolling Lists under heavy updates.
struct UBSegmentedControl<Selection: Hashable>: View {
    struct Segment: Identifiable {
        let id: String
        let title: String
        let value: Selection

        init(id: String, title: String, value: Selection) {
            self.id = id
            self.title = title
            self.value = value
        }
    }

    @Binding var selection: Selection
    let segments: [Segment]

    /// Optional tint for the selected “thumb”. If nil, a subtle default is used.
    var selectedTint: Color? = nil
    /// Optional tint for the container glass/surface. If nil, a subtle default is used.
    var containerTint: Color? = nil

    /// Capsule on iOS 26+, rounded-rect on legacy by default.
    var cornerRadius: CGFloat = 12

    @ScaledMetric(relativeTo: .body) private var controlHeight: CGFloat = 34

    var body: some View {
        if #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *) {
            glassBody
        } else {
            legacyBody
        }
    }

    // MARK: - iOS 26+ (Glass)
    @available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *)
    private var glassBody: some View {
        let capsule = Capsule(style: .continuous)
        return HStack(spacing: 0) {
            ForEach(segments) { segment in
                let isSelected = segment.value == selection
                Button {
                    selection = segment.value
                } label: {
                    Text(segment.title)
                        .font(Typography.subheadlineSemibold)
                        .foregroundStyle(isSelected ? Colors.stylePrimary : Colors.styleSecondary)
                        .frame(maxWidth: .infinity, minHeight: max(controlHeight, 34))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(segment.title)
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
            }
        }
        .padding(2)
        .background(glassContainerBackground)
        .overlay(alignment: .topLeading) {
            GeometryReader { proxy in
                let count = max(segments.count, 1)
                let segmentWidth = proxy.size.width / CGFloat(count)
                let selectedIndex = segments.firstIndex(where: { $0.value == selection }) ?? 0
                // Selected “thumb” is a SOLID tint (no blur) to avoid “blur on blur”
                // when this control sits on top of glass/material-heavy surfaces.
                capsule
                    .fill(glassSelectedSolidFill)
                    .overlay(
                        capsule
                            .strokeBorder(Color.white.opacity(0.16), lineWidth: 0.5)
                            .blendMode(.overlay)
                    )
                    .frame(width: segmentWidth, height: proxy.size.height)
                    .offset(x: CGFloat(selectedIndex) * segmentWidth, y: 0)
                    .animation(.spring(response: 0.22, dampingFraction: 0.9), value: selectedIndex)
            }
            .allowsHitTesting(false)
        }
        // Prevent glass blur bleed outside the capsule.
        .compositingGroup()
        .mask(capsule)
        .contentShape(capsule)
        .accessibilityElement(children: .contain)
    }

    @available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *)
    private var glassContainerBackground: some View {
        Colors.clear
            .glassEffect(
                .regular
                    .tint(glassContainerTint)
                    .interactive(true),
                in: Capsule(style: .continuous)
            )
    }

    @available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *)
    private var glassSelectedTint: Color {
        selectedTint ?? Colors.clear
    }

    @available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *)
    private var glassSelectedSolidFill: Color {
        // Default: a subtle neutral fill that reads on both light/dark without blurring.
        selectedTint ?? Colors.primaryOpacity008
    }

    @available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *)
    private var glassContainerTint: Color {
        containerTint ?? Colors.clear
    }

    // MARK: - Legacy
    private var legacyBody: some View {
        HStack(spacing: 0) {
            ForEach(segments) { segment in
                let isSelected = segment.value == selection
                Button {
                    selection = segment.value
                } label: {
                    Text(segment.title)
                        .font(Typography.subheadlineSemibold)
                        .foregroundStyle(isSelected ? Colors.stylePrimary : Colors.styleSecondary)
                        .frame(maxWidth: .infinity, minHeight: max(controlHeight, 34))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(segment.title)
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
            }
        }
        .padding(2)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Colors.secondaryOpacity008)
        )
        .overlay(alignment: .topLeading) {
            GeometryReader { proxy in
                let count = max(segments.count, 1)
                let segmentWidth = proxy.size.width / CGFloat(count)
                let selectedIndex = segments.firstIndex(where: { $0.value == selection }) ?? 0
                RoundedRectangle(cornerRadius: max(cornerRadius - 2, 8), style: .continuous)
                    .fill(Colors.primaryOpacity008)
                    .frame(width: segmentWidth, height: proxy.size.height)
                    .offset(x: CGFloat(selectedIndex) * segmentWidth, y: 0)
                    .animation(.spring(response: 0.22, dampingFraction: 0.9), value: selectedIndex)
            }
            .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .accessibilityElement(children: .contain)
    }
}
