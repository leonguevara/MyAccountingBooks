//
//  ScheduledTransaction+Extensions.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-09.
//

/// ScheduledTransaction+Extensions
///
/// Convenience behavior for initializing `ScheduledTransaction` Core Data entities.
//

import CoreData

/// Extensions that set defaults on insert for `ScheduledTransaction`.
extension ScheduledTransaction {
    /// Initializes default fields when a `ScheduledTransaction` is first inserted into a context.
    ///
    /// Assigns a new `UUID` to `id`, stamps `createdAt`, and marks the entity as active. Updates are
    /// performed on the entity's context via `context.perform` to ensure thread safety.
    public override nonisolated func awakeFromInsert() {
        super.awakeFromInsert()

        let newID = UUID()
        let now = Date()

        guard let context = self.managedObjectContext else { return }
        let oid = self.objectID

        // Perform updates on the context queue to respect Core Data threading.
        context.perform {
            guard let st = try? context.existingObject(with: oid) as? ScheduledTransaction else { return }
            st.id = newID
            st.createdAt = now
            st.isActive = true
        }
    }
}
