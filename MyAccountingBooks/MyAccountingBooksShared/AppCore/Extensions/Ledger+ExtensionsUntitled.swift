//
//  Ledger+ExtensionsUntitled.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-09.
//

/// Ledger+Extensions
///
/// Convenience behavior for initializing `Ledger` Core Data entities.

import CoreData

/// Extensions that set defaults on insert for `Ledger`.
extension Ledger {
    /// Initializes default fields when a `Ledger` is first inserted into a context.
    ///
    /// Assigns a new `UUID` to `id`, stamps `createdAt`, and marks the ledger as active. Updates are
    /// performed on the entity's context via `context.perform` to ensure thread safety.
    public override nonisolated func awakeFromInsert() {
        super.awakeFromInsert()

        let newID = UUID()
        let now = Date()

        guard let context = self.managedObjectContext else { return }
        let oid = self.objectID

        // Perform updates on the context queue to respect Core Data threading.
        context.perform {
            guard let ledger = try? context.existingObject(with: oid) as? Ledger else { return }
            ledger.id = newID
            ledger.createdAt = now
            ledger.isActive = true
        }
    }
}
