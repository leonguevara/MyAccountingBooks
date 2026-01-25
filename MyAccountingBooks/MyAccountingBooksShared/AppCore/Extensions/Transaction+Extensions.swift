//
//  Transaction+Extensions.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-09.
//

/// Transaction+Extensions
///
/// Convenience behavior for initializing `Transaction` Core Data entities.
//

import CoreData

/// Extensions that set defaults on insert for `Transaction`.
extension Transaction {
    /// Initializes default fields when a `Transaction` is first inserted into a context.
    ///
    /// Assigns a new `UUID` to `id`, stamps `postDate`, and sets `isVoided` to `false`. Updates are
    /// performed on the entity's context via `context.perform` to ensure thread safety.
    public override nonisolated func awakeFromInsert() {
        super.awakeFromInsert()

        let newID = UUID()
        let now = Date()

        guard let context = self.managedObjectContext else { return }
        let oid = self.objectID

        // Perform updates on the context queue to respect Core Data threading.
        context.perform {
            guard let txn = try? context.existingObject(with: oid) as? Transaction else { return }
            txn.id = newID
            txn.postDate = now
            txn.isVoided = false
        }
    }
}
