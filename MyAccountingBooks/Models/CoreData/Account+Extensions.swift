//
//  Account+Extensions.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-09.
//

import CoreData

extension Account {
    public override nonisolated func awakeFromInsert() {
        super.awakeFromInsert()

        let newID = UUID()
        let now = Date()

        guard let context = self.managedObjectContext else { return }
        let oid = self.objectID

        context.perform {
            guard let account = try? context.existingObject(with: oid) as? Account else { return }
            account.id = newID
            account.createdAt = now
            account.isActive = true
            account.isPlaceholder = false
            account.accountRole = 0
        }
    }

    // Computed properties (safe)
    var isRoot: Bool {
        parent == nil && ledger?.rootAccount == self
    }
}
