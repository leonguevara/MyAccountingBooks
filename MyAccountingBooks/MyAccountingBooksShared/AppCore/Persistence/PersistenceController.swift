//
//  PersistenceController.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-08.
//

/// PersistenceController
///
/// Core Data + CloudKit stack for MyAccountingBooks. Creates and configures an
/// `NSPersistentCloudKitContainer`, exposes a `viewContext`, and provides lifecycle
/// helpers for loading and (optionally) resetting the local store.
//

import Foundation
import CoreData

/// The application's Core Data persistence layer backed by CloudKit.
///
/// Provides a shared singleton, a configured `NSPersistentCloudKitContainer`, and convenience
/// APIs to load persistent stores on demand. The controller runs on the main actor because
/// its `viewContext` is injected into SwiftUI views.
@MainActor
final class PersistenceController {
    /// Global singleton instance used throughout the app.
    static let shared = PersistenceController()
    
    /// The CloudKit-backed persistent container.
    private(set) var container: NSPersistentCloudKitContainer
    /// Tracks whether persistent stores have been loaded to avoid duplicate work.
    private var loaded = false
    
    /// The main-queue managed object context for use with SwiftUI.
    ///
    /// - Note: Configured to automatically merge changes from parent and to use
    ///   `NSMergeByPropertyStoreTrumpMergePolicy` after stores are loaded.
    var viewContext: NSManagedObjectContext { container.viewContext }
    
    /// Initializes the persistence controller.
    ///
    /// - Parameter inMemory: When true, configures the store to use `/dev/null` for ephemeral data
    ///   (useful for previews and tests). Otherwise, uses the default SQLite location.
    init(inMemory: Bool = false) {
        container = Self.makeContainer(inMemory: inMemory)
        loadStoresIfNeeded()
    }
    
    /// Creates and configures the CloudKit-backed persistent container.
    ///
    /// Enables history tracking and remote change notifications. When `inMemory` is true,
    /// the store URL is set to `/dev/null` to avoid writing to disk.
    private static func makeContainer(inMemory: Bool) -> NSPersistentCloudKitContainer {
        let c = NSPersistentCloudKitContainer(name: "MyAccountingBooks")
        // Configure the first (default) store description with history and remote change notifications.
        if let desc = c.persistentStoreDescriptions.first {
            // Enable persistent history tracking and remote change notifications.
            desc.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            desc.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            // Use an in-memory store for previews/tests.
            if inMemory {
                desc.url = URL(fileURLWithPath: "/dev/null")
            }
        }
        
        return c
    }
    
    /// Loads the persistent stores once and configures the main context for UI usage.
    ///
    /// Sets `automaticallyMergesChangesFromParent = true` and uses the store-trumps merge policy
    /// to prefer remote/store changes when resolving conflicts.
    func loadStoresIfNeeded() {
        guard !loaded else { return }
        
        container.loadPersistentStores { _, error in
            if let error {
                // Fatal during development; consider surfacing a user-facing error in production builds.
                fatalError("Unresolved error \(error)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        
        loaded = true
    }
    
    /// Resets the local persistent store (destructive).
    ///
    /// Destroys the SQLite store files on disk and rebuilds the container. With CloudKit enabled,
    /// the data may be re-downloaded from iCloud after reset. Use with caution.
    func resetLocalStore() throws {
        loadStoresIfNeeded()
        
        let coordinator = container.persistentStoreCoordinator
        for store in coordinator.persistentStores {
            guard let url = store.url else { continue }
            
            // Destroy the on-disk SQLite store.
            try coordinator.destroyPersistentStore(
                at: url,
                ofType: NSSQLiteStoreType,
                options: store.options
            )
            
            // Remove auxiliary WAL/SHM files if present.
            try? FileManager.default.removeItem(at: url)
            try? FileManager.default.removeItem(at: url.appendingPathExtension("-wal"))
            try? FileManager.default.removeItem(at: url.appendingPathExtension("-shm"))
        }
        
        // Reconstruye el container y recarga
        loaded = false
        container = Self.makeContainer(inMemory: false)
        loadStoresIfNeeded()
    }
}

