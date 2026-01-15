import SwiftUI

// MARK: - MotionTokens
/// DesignSystemV2 motion tuning tokens.
///
/// Keep values 1:1 with legacy `DS.Motion` while migrating call sites.
enum MotionTokens {
    // MARK: Card Background Tuning
    /// How quickly the background follows device tilt. Lower = smoother (default 0.12).
    static let smoothingAlpha: Double = 0.12
    /// How far the background is allowed to move. 0.22 is subtle; raise to make bolder.
    static let cardBackgroundAmplitudeScale: Double = 0.22
}

