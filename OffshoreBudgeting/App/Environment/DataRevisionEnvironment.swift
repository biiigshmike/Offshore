import SwiftUI

private struct DataRevisionKey: EnvironmentKey {
    static let defaultValue: Int = 0
}

extension EnvironmentValues {
    // PLATFORM: KEEP
    var dataRevision: Int {
        get { self[DataRevisionKey.self] }
        set { self[DataRevisionKey.self] = newValue }
    }
}
