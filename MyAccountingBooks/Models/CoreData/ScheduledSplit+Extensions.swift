//
//  ScheduledSplit+Extensions.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-09.
//

/// ScheduledSplit+Extensions
///
/// Convenience behavior for initializing `ScheduledSplit` Core Data entities.
//

import CoreData

/// Extensions that set defaults on insert for `ScheduledSplit`.
extension ScheduledSplit {
    /// Initializes default fields when a `ScheduledSplit` is first inserted into a context.
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
            guard let ss = try? context.existingObject(with: oid) as? ScheduledSplit else { return }
            ss.id = newID
        }
    }
}

