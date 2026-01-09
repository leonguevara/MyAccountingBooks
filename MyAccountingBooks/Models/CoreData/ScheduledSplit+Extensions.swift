//
//  ScheduledSplit+Extensions.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-09.
//

import CoreData

extension ScheduledSplit {
    public override nonisolated func awakeFromInsert() {
        super.awakeFromInsert()

        let newID = UUID()

        guard let context = self.managedObjectContext else { return }
        let oid = self.objectID

        context.perform {
            guard let ss = try? context.existingObject(with: oid) as? ScheduledSplit else { return }
            ss.id = newID
        }
    }
}
