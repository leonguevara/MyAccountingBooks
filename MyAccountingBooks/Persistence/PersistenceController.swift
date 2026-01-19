//
//  PersistenceController.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-08.
//

import Foundation
import CoreData

@MainActor
final class PersistenceController {
    static let shared = PersistenceController()
    
    private(set) var container: NSPersistentCloudKitContainer
    private var loaded = false
    
    var viewContext: NSManagedObjectContext { container.viewContext }
    
    init(inMemory: Bool = false) {
        container = Self.makeContainer(inMemory: inMemory)
    }
    
    private static func makeContainer(inMemory: Bool) -> NSPersistentCloudKitContainer {
        let c = NSPersistentCloudKitContainer(name: "MyAccountingBooks")
        
        if let desc = c.persistentStoreDescriptions.first {
            desc.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            desc.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            if inMemory {
                desc.url = URL(fileURLWithPath: "/dev/null")
            }
        }
        
        return c
    }
    
    /*init(inMemory: Bool = false) {
     container = NSPersistentCloudKitContainer(name: "MyAccountingBooks")
     
     if let desc = container.persistentStoreDescriptions.first {
     desc.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
     desc.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
     if inMemory {
     desc.url = URL(fileURLWithPath: "/dev/null")
     }
     }
     }*/
    
    func loadStoresIfNeeded() {
        guard !loaded else { return }
        
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Unresolved error \(error)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        
        loaded = true
    }
    
    /// ⚠️ Reset LOCAL del store.
    /// Con CloudKit activo, esto puede re-descargar datos.
    func resetLocalStore() throws {
        loadStoresIfNeeded()
        
        let coordinator = container.persistentStoreCoordinator
        for store in coordinator.persistentStores {
            guard let url = store.url else { continue }
            
            // Destruye el persistent store (SQLite)
            try coordinator.destroyPersistentStore(
                at: url,
                ofType: NSSQLiteStoreType,
                options: store.options
            )
            
            // Limpia archivos auxiliares wal/shm (por si quedaron)
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
