//
//  Price+Extensions.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-09.
//

/// Price+Extensions
///
/// Convenience behavior for initializing `Price` Core Data entities.
//

import CoreData

/// Extensions that set defaults on insert for `Price`.
extension Price {
    /// Initializes default fields when a `Price` is first inserted into a context.
    ///
    /// Assigns a new `UUID` to `id` and stamps `createdAt`. Updates are performed on the entity's
    /// context via `context.perform` to ensure thread safety.
    public override nonisolated func awakeFromInsert() {
        super.awakeFromInsert()

        let newID = UUID()
        let now = Date()

        guard let context = self.managedObjectContext else { return }
        let oid = self.objectID

        // Perform updates on the context queue to respect Core Data threading.
        context.perform {
            guard let price = try? context.existingObject(with: oid) as? Price else { return }
            price.id = newID
            price.createdAt = now
        }
    }
}
