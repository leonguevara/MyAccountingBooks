//
//  Payee+Extensions.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-09.
//

import CoreData

extension Payee {
    public override nonisolated func awakeFromInsert() {
        super.awakeFromInsert()

        let newID = UUID()

        guard let context = self.managedObjectContext else { return }
        let oid = self.objectID

        context.perform {
            guard let payee = try? context.existingObject(with: oid) as? Payee else { return }
            payee.id = newID
            payee.isActive = true
        }
    }
}
