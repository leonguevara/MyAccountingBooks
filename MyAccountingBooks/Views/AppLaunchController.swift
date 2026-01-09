//
//  AppLaunchController.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-08.
//

import Foundation
import CoreData
import Combine

@MainActor
final class AppLaunchController: ObservableObject {
    @Published var phase: LaunchPhase = .checkingICloud
    @Published var isSyncing: Bool = false

    private weak var persistence: PersistenceController?
    private var syncToken: NSObjectProtocol?

    func start(using persistence: PersistenceController) {
        self.persistence = persistence
        Task { await run() }
    }

    func retry() {
        guard let persistence else { return }
        start(using: persistence)
    }

    private func run() async {
        phase = .checkingICloud

        let status = await CloudKitAccountChecker.checkAccountStatus()
        switch status {
        case .failure(let error):
            phase = .iCloudUnavailable(message: error.localizedDescription)
            return
        case .success:
            break
        }

        phase = .loadingStore
        persistence?.loadStoresIfNeeded()
        startMonitoringCloudKitEvents()

        phase = .syncing
        try? await Task.sleep(nanoseconds: 800_000_000)

        guard let ctx = persistence?.viewContext else {
            phase = .iCloudUnavailable(message: "No se pudo inicializar Core Data.")
            return
        }

        let count = (try? ctx.count(for: Ledger.fetchRequest())) ?? 0
        phase = .ready(hasData: count > 0)
    }

    private func startMonitoringCloudKitEvents() {
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

    deinit {
        if let syncToken { NotificationCenter.default.removeObserver(syncToken) }
    }
}
