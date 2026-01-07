//
//  AppLockView.swift
//  OffshoreBudgeting
//
//  Created by Michael Brown on 2025-10-31.
//  Description: A full-screen overlay that asks users to unlock with biometrics.
//  Place it as an overlay atop your root content.
//

import SwiftUI

// MARK: - AppLockView
/// A full-screen lock overlay that integrates with AppLockViewModel.
/// - Inject `viewModel` from your Environment or init directly.
/// - When `isLocked` is true, this view blocks interaction behind a blurred layer.
/// - Tap the button to request Face ID / Touch ID.
public struct AppLockView: View {

    // MARK: Dependencies
    @ObservedObject private var viewModel: AppLockViewModel

    // MARK: Init
    public init(viewModel: AppLockViewModel) {
        self.viewModel = viewModel
    }

    // MARK: Body
    public var body: some View {
        ZStack {
            // Background blur to hide sensitive data behind the lock
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 16) {
//                Image(systemName: viewModel.lockIconName)
//                    .font(.system(size: 44, weight: .regular, design: .rounded))
//                    .accessibilityHidden(true)
//
//                Text("Offshore Budgeting is Locked")
//                    .font(.title3)
//                    .multilineTextAlignment(.center)

//                if viewModel.isAuthenticating {
//                    ProgressView("Authenticating…")
//                        .font(.footnote)
//                }

                if let error = viewModel.lastErrorMessage {
                    Text(error)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                        .accessibilityLabel("Authentication Error")
                        .accessibilityValue(error)
                }
            }
            .padding(24)
            .frame(maxWidth: 400)
        }
        .accessibilityAddTraits(.isModal)
    }

}
