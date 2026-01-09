//
//  Commodity+Extensions.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-09.
//

import CoreData

extension Commodity {
    public override nonisolated func awakeFromInsert() {
        super.awakeFromInsert()

        let newID = UUID()

        guard let context = self.managedObjectContext else { return }
        let oid = self.objectID

        context.perform {
            guard let commodity = try? context.existingObject(with: oid) as? Commodity else { return }
            commodity.id = newID
            commodity.isActive = true
        }
    }

    // Helpers no mutan estado; se quedan limpios.
    var isCurrency: Bool {
        namespace == "CURRENCY"
    }
}
