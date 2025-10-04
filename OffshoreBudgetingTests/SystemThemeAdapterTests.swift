import Testing
@testable import Offshore

struct SystemThemeAdapterTests {

    @Test
    func flavor_prefersLiquidGlassWhenTranslucencySupported() {
        let capabilities = PlatformCapabilities(
            supportsOS26Translucency: true,
            supportsAdaptiveKeypad: true
        )

        #expect(SystemThemeAdapter.flavor(for: capabilities) == .liquid)
    }

    @Test
    func flavor_fallsBackToClassicWhenTranslucencyUnavailable() {
        let capabilities = PlatformCapabilities(
            supportsOS26Translucency: false,
            supportsAdaptiveKeypad: false
        )

        #expect(SystemThemeAdapter.flavor(for: capabilities) == .classic)
    }
}
