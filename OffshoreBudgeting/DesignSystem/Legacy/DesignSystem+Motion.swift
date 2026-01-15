//
//  DesignSystem+Motion.swift
//  SoFar
//
//  Central place for motion tuning values.
//

import SwiftUI

extension DS {
    enum Motion {
        // MARK: Card Background Tuning
        /// How quickly the background follows device tilt. Lower = smoother (default 0.12).
        static let smoothingAlpha: Double = MotionTokens.smoothingAlpha
        /// How far the background is allowed to move. 0.22 is subtle; raise to make bolder.
        static let cardBackgroundAmplitudeScale: Double = MotionTokens.cardBackgroundAmplitudeScale
    }
}
