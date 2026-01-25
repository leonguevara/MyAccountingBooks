//
//  Split+Extensions.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-09.
//

/// Split+Extensions
///
/// Convenience behavior and computed helpers for the `Split` Core Data entity.
//

import CoreData

/// Extensions that set defaults on insert and provide amount computation helpers.
extension Split {
    /// Initializes default fields when a `Split` is first inserted into a context.
    ///
    /// Assigns a new `UUID` to `id` and sets `reconcileState` to `false`. Updates are performed on the
    /// entity's context via `context.perform` to ensure thread safety.
    public override nonisolated func awakeFromInsert() {
        super.awakeFromInsert()

        let newID = UUID()

        guard let context = self.managedObjectContext else { return }
        let oid = self.objectID

        // Perform updates on the context queue to respect Core Data threading.
        context.perform {
            guard let split = try? context.existingObject(with: oid) as? Split else { return }
            split.id = newID
            split.reconcileState = false
        }
    }

    /// The signed amount for the split, based on its `side`.
    ///
    /// Interprets `side` as 0 = debit (positive) and 1 = credit (negative). Any other value
    /// falls back to treating the amount as positive. Uses `amountDecimal` as the magnitude.
    var signedAmount: Decimal {
        let magnitude = amountDecimal
        switch side {
        case 0:  return magnitude
        case 1:  return -magnitude
        default: return magnitude
        }
    }
    
    /// Converts the rational amount (`valueNum` / `valueDenom`) into a Decimal.
    ///
    /// If `valueDenom` is zero, a denominator of 1 is used to avoid division by zero. Division
    /// is performed with `.bankers` rounding via `NSDecimalDivide`.
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

