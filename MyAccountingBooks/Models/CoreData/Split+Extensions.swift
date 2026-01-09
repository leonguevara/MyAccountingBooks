//
//  Split+Extensions.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-09.
//

import CoreData

extension Split {
    public override nonisolated func awakeFromInsert() {
        super.awakeFromInsert()

        let newID = UUID()

        guard let context = self.managedObjectContext else { return }
        let oid = self.objectID

        context.perform {
            guard let split = try? context.existingObject(with: oid) as? Split else { return }
            split.id = newID
            split.reconcileState = false
        }
    }

    // Si tu modelo tiene side como Int16 (0="DEBIT" / 1="CREDIT") y amount Int64:
    var signedAmount: Decimal {
        let magnitude = amountDecimal
        switch side {
        case 0:  return magnitude
        case 1:  return -magnitude
        default: return magnitude
        }
    }
    
    var amountDecimal: Decimal {
            // valueNum: Int64, valueDenom: Int64 (ej. 100 para centavos)
            let denom = valueDenom == 0 ? 1 : valueDenom

            var num = Decimal(valueNum)
            var den = Decimal(denom)

            // num / den
            var result = Decimal()
            NSDecimalDivide(&result, &num, &den, .bankers)

            return result
        }
}
