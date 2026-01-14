//
//  AccountBalanceService.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-11.
//

import Foundation
import CoreData

/// Balance calculado para una cuenta.
/// - own: sólo movimientos directos de la cuenta
/// - total: own + descendientes (si se solicita)
struct AccountBalance {
    let own: Decimal
    let total: Decimal
}

enum AccountBalanceService {

    /// Calcula balances para todas las cuentas del ledger.
    /// - Parameters:
    ///   - ledger: ledger
    ///   - context: moc
    ///   - includeDescendants: si true, total incluye hijos
    static func computeBalances(
        ledger: Ledger,
        context: NSManagedObjectContext,
        includeDescendants: Bool
    ) throws -> [NSManagedObjectID: AccountBalance] {

        // 1) Obtén todas las cuentas del ledger
        let accountReq = Account.fetchRequest()
        accountReq.predicate = NSPredicate(format: "ledger == %@", ledger)

        let accounts = try context.fetch(accountReq) as! [Account]

        // index por objectID
        var childrenByParent: [NSManagedObjectID: [Account]] = [:]
        var roots: [Account] = []

        for acc in accounts {
            if let parent = acc.parent {
                childrenByParent[parent.objectID, default: []].append(acc)
            } else {
                roots.append(acc)
            }
        }

        // 2) Suma de splits por cuenta (own balance “contable”)
        // Asumimos: Split tiene account, valueNum, valueDenom, side
        let splitReq = Split.fetchRequest()
        splitReq.predicate = NSPredicate(format: "account.ledger == %@", ledger)

        let splits = try context.fetch(splitReq) as! [Split]

        var own: [NSManagedObjectID: Decimal] = [:]
        own.reserveCapacity(accounts.count)

        for sp in splits {
            guard let acc = sp.account else { continue }
            let amount = splitValue(sp)
            let signed = signedAmount(amount: amount, split: sp, account: acc)
            own[acc.objectID, default: 0] += signed
        }

        // 3) Propaga a padres (total)
        var result: [NSManagedObjectID: AccountBalance] = [:]

        func dfs(_ acc: Account) -> Decimal {
            let ownValue = own[acc.objectID, default: 0]
            if !includeDescendants {
                result[acc.objectID] = AccountBalance(own: ownValue, total: ownValue)
                return ownValue
            }

            let kids = childrenByParent[acc.objectID, default: []]
            let kidsTotal = kids.reduce(Decimal(0)) { partial, child in
                partial + dfs(child)
            }
            let total = ownValue + kidsTotal
            result[acc.objectID] = AccountBalance(own: ownValue, total: total)
            return total
        }

        for r in roots {
            _ = dfs(r)
        }

        return result
    }

    // MARK: - Helpers

    private static func splitValue(_ sp: Split) -> Decimal {
        let denom = sp.valueDenom == 0 ? 1 : sp.valueDenom
        return Decimal(sp.valueNum) / Decimal(denom)
    }

    /// Regla de signo estilo contable.
    /// Ajusta aquí según tu codificación:
    /// - side: 0 = DEBIT, 1 = CREDIT (ejemplo)
    /// - accountType.kind: enum (Asset, Liability, Equity, Income, Expense, etc.)
    private static func signedAmount(amount: Decimal, split: Split, account: Account) -> Decimal {
        let isDebit = (split.side == 0)

        let kind = account.accountType?.kind ?? 0
        // Ejemplo de mapping: ajústalo a tu enum real
        // 0 Asset, 1 Liability, 2 Equity, 3 Income, 4 Expense
        switch kind {
        case 0, 4: // Asset / Expense: Debe suma, Haber resta
            return isDebit ? amount : -amount
        case 1, 2, 3: // Liability/Equity/Income: Haber suma, Debe resta
            return isDebit ? -amount : amount
        default:
            // fallback conservador: Debe suma
            return isDebit ? amount : -amount
        }
    }
}
