//
//  Recurrence+Extensions.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-09.
//

import CoreData

extension Recurrence {
    public override nonisolated func awakeFromInsert() {
        super.awakeFromInsert()

        let newID = UUID()

        guard let context = self.managedObjectContext else { return }
        let oid = self.objectID

        context.perform {
            guard let rec = try? context.existingObject(with: oid) as? Recurrence else { return }
            rec.id = newID
        }
    }
}
