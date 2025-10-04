import Foundation
import Testing
@testable import Offshore

#if targetEnvironment(macCatalyst)
@MainActor
struct PlatformCapabilitiesTests {

    @Test
    func macCatalyst26_enablesLiquidGlass() {
        guard #available(macCatalyst 26.0, *) else { return }

        let capabilities = PlatformCapabilities.current
        #expect(capabilities.supportsOS26Translucency)
    }
}
#endif
