//
//  AccountOwner+Extensions.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-09.
//

import CoreData

extension AccountOwner {
    public override nonisolated func awakeFromInsert() {
        super.awakeFromInsert()

        let newID = UUID()
        let now = Date()
        let oid = self.objectID

        guard let context = self.managedObjectContext else { return }

        context.perform { [oid, newID, now] in
            guard let owner = try? context.existingObject(with: oid) as? AccountOwner else { return }
            owner.id = newID
            owner.createdAt = now
            owner.isActive = true
        }
    }
}
