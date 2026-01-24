//
//  AppLaunchController.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-08.
//

/// AppLaunchController
///
/// Coordinates app launch by checking iCloud availability, loading Core Data stores,
/// and monitoring CloudKit sync events to inform the UI about launch progress.

import Foundation
import CoreData
import Combine

/// A main-actor observable controller that advances the app through its launch phases.
///
/// Sequence:
/// 1. Check iCloud account status.
/// 2. Load persistent stores.
/// 3. Begin monitoring CloudKit events and reflect syncing state.
/// 4. Determine whether initial data exists and transition to ready.
@MainActor
final class AppLaunchController: ObservableObject {
    /// Current phase of the launch flow, used to drive the UI state machine.
    @Published var phase: LaunchPhase = .checkingICloud
    /// Indicates whether a CloudKit sync event is currently in progress.
    @Published var isSyncing: Bool = false

    /// Weak reference to the persistence stack used to load stores and provide a view context.
    private weak var persistence: PersistenceController?
    /// Notification token for CloudKit event monitoring.
    private var syncToken: NSObjectProtocol?

    /// Starts the launch flow using the provided persistence controller.
    ///
    /// - Parameter persistence: The Core Data stack to initialize and query during launch.
    func start(using persistence: PersistenceController) {
        self.persistence = persistence
        Task { await run() }
    }

    /// Retries the launch sequence from the beginning using the last provided persistence controller.
    func retry() {
        guard let persistence else { return }
        start(using: persistence)
    }

    /// Internal async sequence that advances through the launch phases and updates published state.
    private func run() async {
        // Begin by checking whether iCloud is available and the user is signed in.
        phase = .checkingICloud

        // Query iCloud account status asynchronously.
        let status = await CloudKitAccountChecker.checkAccountStatus()
        switch status {
        case .failure(let error):
            phase = .iCloudUnavailable(message: error.localizedDescription)
            return
        case .success:
            break
        }

        // iCloud available; proceed to load persistent stores.
        phase = .loadingStore
        persistence?.loadStoresIfNeeded()
        // Start listening for CloudKit event changes to reflect syncing progress.
        startMonitoringCloudKitEvents()

        // Briefly transition to syncing; allow time for initial events to arrive.
        phase = .syncing
        try? await Task.sleep(nanoseconds: 800_000_000)

        // Ensure we have a view context; otherwise report a Core Data initialization error.
        guard let ctx = persistence?.viewContext else {
            phase = .iCloudUnavailable(message: "No se pudo inicializar Core Data.")
            return
        }

        // Determine whether there is existing data to decide the ready state.
        let count = (try? ctx.count(for: Ledger.fetchRequest())) ?? 0
        phase = .ready(hasData: count > 0)
    }

    /// Subscribes to `NSPersistentCloudKitContainer.eventChangedNotification` to update `isSyncing`.
    ///
    /// The controller sets `isSyncing = true` while an event has no `endDate`, and resets it when the
    /// event completes.
    private func startMonitoringCloudKitEvents() {
        // Avoid duplicate subscriptions.
        guard syncToken == nil else { return }

        syncToken = NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let self else { return }
            guard let event = note.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                    as? NSPersistentCloudKitContainer.Event else { return }
            Task { @MainActor in
                self.isSyncing = (event.endDate == nil)
            }
        }
    }

    /// Cleans up the CloudKit event observer on deallocation.
    deinit {
        if let syncToken { NotificationCenter.default.removeObserver(syncToken) }
    }
}
