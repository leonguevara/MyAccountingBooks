//
//  Transaction+Extensions.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-09.
//

import CoreData

extension Transaction {
    public override nonisolated func awakeFromInsert() {
        super.awakeFromInsert()

        let newID = UUID()
        let now = Date()

        guard let context = self.managedObjectContext else { return }
        let oid = self.objectID

        context.perform {
            guard let txn = try? context.existingObject(with: oid) as? Transaction else { return }
            txn.id = newID
            txn.postDate = now
            txn.isVoided = false
        }
    }
}
