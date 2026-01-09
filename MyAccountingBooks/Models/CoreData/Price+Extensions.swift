//
//  Price+Extensions.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-09.
//

import CoreData

extension Price {
    public override nonisolated func awakeFromInsert() {
        super.awakeFromInsert()

        let newID = UUID()
        let now = Date()

        guard let context = self.managedObjectContext else { return }
        let oid = self.objectID

        context.perform {
            guard let price = try? context.existingObject(with: oid) as? Price else { return }
            price.id = newID
            price.createdAt = now
        }
    }
}
