//
//  Account+Extensions.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-09.
//

/// Account+Extensions
///
/// Convenience behaviors and helpers for the `Account` Core Data entity.

import CoreData

/// Extensions that configure default values on insert and provide convenience properties.
extension Account {
    /// Initializes default fields when an `Account` is first inserted into a context.
    ///
    /// Sets a new `UUID` for `id`, stamps `createdAt`, and initializes flags (`isActive`,
    /// `isPlaceholder`, and `accountRole`). The updates are performed on the entity's context
    /// via `context.perform` to ensure thread safety.
    public override nonisolated func awakeFromInsert() {
        super.awakeFromInsert()

        let newID = UUID()
        let now = Date()

        guard let context = self.managedObjectContext else { return }
        let oid = self.objectID

        // Perform updates on the context queue to respect Core Data threading.
        context.perform {
            guard let account = try? context.existingObject(with: oid) as? Account else { return }
            account.id = newID
            account.createdAt = now
            account.isActive = true
            account.isPlaceholder = false
            account.accountRole = 0
        }
    }

    /// Indicates whether this account is the root of its ledger.
    ///
    /// Returns true when the account has no parent and matches the ledger's `rootAccount`.
    var isRoot: Bool {
        parent == nil && ledger?.rootAccount == self
    }
}

