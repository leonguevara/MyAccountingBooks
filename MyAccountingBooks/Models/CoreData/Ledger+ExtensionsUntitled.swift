//
//  Ledger+ExtensionsUntitled.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-09.
//

import CoreData

extension Ledger {
    public override nonisolated func awakeFromInsert() {
        super.awakeFromInsert()

        let newID = UUID()
        let now = Date()

        guard let context = self.managedObjectContext else { return }
        let oid = self.objectID

        context.perform {
            guard let ledger = try? context.existingObject(with: oid) as? Ledger else { return }
            ledger.id = newID
            ledger.createdAt = now
            ledger.isActive = true
        }
    }
}
