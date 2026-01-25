//
//  Commodity+Extensions.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-09.
//

/// Commodity+Extensions
///
/// Convenience behavior and helpers for the `Commodity` Core Data entity.

import CoreData

/// Extensions that set defaults on insert and provide read-only helpers.
extension Commodity {
    /// Initializes default fields when a `Commodity` is first inserted into a context.
    ///
    /// Assigns a new `UUID` to `id` and marks the commodity as active. Updates are performed on the
    /// entity's context via `context.perform` to ensure thread safety.
    public override nonisolated func awakeFromInsert() {
        super.awakeFromInsert()

        let newID = UUID()

        guard let context = self.managedObjectContext else { return }
        let oid = self.objectID

        // Perform updates on the context queue to respect Core Data threading.
        context.perform {
            guard let commodity = try? context.existingObject(with: oid) as? Commodity else { return }
            commodity.id = newID
            commodity.isActive = true
        }
    }

    /// Indicates whether the commodity represents a currency.
    ///
    /// Returns true when `namespace == "CURRENCY"`.
    var isCurrency: Bool {
        namespace == "CURRENCY"
    }
}

