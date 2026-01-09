//
//  AccountType+Extensions.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-09.
//

import CoreData

extension AccountType {
    public override nonisolated func awakeFromInsert() {
        super.awakeFromInsert()

        let newID = UUID()

        guard let context = self.managedObjectContext else { return }
        let oid = self.objectID

        context.perform {
            guard let type = try? context.existingObject(with: oid) as? AccountType else { return }
            type.id = newID
            type.isActive = true
        }
    }
}
