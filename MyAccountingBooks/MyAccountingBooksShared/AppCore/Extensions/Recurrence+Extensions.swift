//
//  Recurrence+Extensions.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-09.
//

/// Recurrence+Extensions
///
/// Convenience behavior for initializing `Recurrence` Core Data entities.
//

import CoreData

/// Extensions that set defaults on insert for `Recurrence`.
extension Recurrence {
    /// Initializes default fields when a `Recurrence` is first inserted into a context.
    ///
    /// Assigns a new `UUID` to `id`. Updates are performed on the entity's context via
    /// `context.perform` to ensure thread safety.
    public override nonisolated func awakeFromInsert() {
        super.awakeFromInsert()

        let newID = UUID()

        guard let context = self.managedObjectContext else { return }
        let oid = self.objectID

        // Perform updates on the context queue to respect Core Data threading.
        context.perform {
            guard let rec = try? context.existingObject(with: oid) as? Recurrence else { return }
            rec.id = newID
        }
    }
}
