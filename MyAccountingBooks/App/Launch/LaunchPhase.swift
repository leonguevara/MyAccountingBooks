//
//  LaunchPhase.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-08.
//

/// LaunchPhase
///
/// Defines the states the app transitions through during startup and initial sync.

import Foundation

/// Discrete phases of the app's launch flow.
///
/// These values are used by the UI to drive progress and error presentation while the app checks
/// iCloud availability, loads persistent stores, and determines readiness.
enum LaunchPhase: Equatable {
    /// Checking whether iCloud is available and the user is signed in.
    case checkingICloud
    /// iCloud is unavailable or not signed in; includes a user-facing error message.
    case iCloudUnavailable(message: String)
    /// Loading Core Data persistent stores.
    case loadingStore
    /// Waiting for initial CloudKit sync events to complete.
    case syncing
    /// Ready to present the app; `hasData` indicates whether initial content exists.
    case ready(hasData: Bool)
}
