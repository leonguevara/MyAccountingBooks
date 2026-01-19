//
//  AccountOwner+Extensions.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-09.
//

/// AccountOwner+Extensions
///
/// Convenience behaviors for initializing `AccountOwner` Core Data entities.

import CoreData

/// Extensions that set defaults on insert for `AccountOwner`.
extension AccountOwner {
    /// Initializes default fields when an `AccountOwner` is first inserted into a context.
    ///
    /// Assigns a new `UUID` to `id`, sets `createdAt` to the current date, and marks the owner as active.
    /// Updates are performed on the entity's context via `context.perform` to ensure thread safety.
    public override nonisolated func awakeFromInsert() {
        super.awakeFromInsert()

        let newID = UUID()
        let now = Date()
        let oid = self.objectID

        guard let context = self.managedObjectContext else { return }

        // Perform updates on the context's queue to respect Core Data threading.
        context.perform { [oid, newID, now] in
            guard let owner = try? context.existingObject(with: oid) as? AccountOwner else { return }
            owner.id = newID
            owner.createdAt = now
            owner.isActive = true
        }
    }
}

