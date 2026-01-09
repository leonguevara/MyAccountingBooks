//
//  ScheduledTransaction+Extensions.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-09.
//

import CoreData

extension ScheduledTransaction {
    public override nonisolated func awakeFromInsert() {
        super.awakeFromInsert()

        let newID = UUID()
        let now = Date()

        guard let context = self.managedObjectContext else { return }
        let oid = self.objectID

        context.perform {
            guard let st = try? context.existingObject(with: oid) as? ScheduledTransaction else { return }
            st.id = newID
            st.createdAt = now
            st.isActive = true
        }
    }
}
