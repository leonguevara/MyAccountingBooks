//
//  AccountType+Extensions.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-09.
//

/// AccountType+Extensions
///
/// Convenience behavior for initializing `AccountType` Core Data entities.

import CoreData

/// Extensions that set defaults on insert for `AccountType`.
extension AccountType {
    /// Initializes default fields when an `AccountType` is first inserted into a context.
    ///
    /// Assigns a new `UUID` to `id` and marks the type as active. Updates are performed on the
    /// entity's context via `context.perform` to ensure thread safety.
    public override nonisolated func awakeFromInsert() {
        super.awakeFromInsert()

        let newID = UUID()

        guard let context = self.managedObjectContext else { return }
        let oid = self.objectID

        // Perform updates on the context queue to respect Core Data threading.
        context.perform {
            guard let type = try? context.existingObject(with: oid) as? AccountType else { return }
            type.id = newID
            type.isActive = true
        }
    }
}
