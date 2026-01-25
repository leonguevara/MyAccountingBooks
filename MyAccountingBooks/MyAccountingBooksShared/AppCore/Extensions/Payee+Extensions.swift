//
//  Payee+Extensions.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-09.
//

/// Payee+Extensions
///
/// Convenience behavior for initializing `Payee` Core Data entities.
//

import CoreData

/// Extensions that set defaults on insert for `Payee`.
extension Payee {
    /// Initializes default fields when a `Payee` is first inserted into a context.
    ///
    /// Assigns a new `UUID` to `id` and marks the payee as active. Updates are performed on the
    /// entity's context via `context.perform` to ensure thread safety.
    public override nonisolated func awakeFromInsert() {
        super.awakeFromInsert()

        let newID = UUID()

        guard let context = self.managedObjectContext else { return }
        let oid = self.objectID

        // Perform updates on the context queue to respect Core Data threading.
        context.perform {
            guard let payee = try? context.existingObject(with: oid) as? Payee else { return }
            payee.id = newID
            payee.isActive = true
        }
    }
}
