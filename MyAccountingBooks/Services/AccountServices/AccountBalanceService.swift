//
//  AccountBalanceService.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-11.
//

import Foundation
import CoreData

/// A pair of balances for an account.
///
/// - `own`: The balance contributed by the account's own splits only (no descendants).
/// - `total`: The balance including all descendant accounts (equal to `own` when descendants
///   are excluded or there are none).
struct AccountBalance {
    let own: Decimal
    let total: Decimal
}

/// Utilities for computing account balances for a ledger.
///
/// Provides depth-first aggregation of split values into per-account balances, with optional
/// inclusion of descendant accounts. Results are returned as a dictionary keyed by
/// `NSManagedObjectID` to avoid retaining full managed objects.
enum AccountBalanceService {

    /// Computes per-account balances for the given ledger.
    ///
    /// The method fetches all `Account` and `Split` objects for the ledger, aggregates each
    /// account's own balance from its splits (respecting debit/credit sign rules by account kind),
    /// then performs a depth-first traversal to optionally include descendant balances.
    ///
    /// - Parameters:
    ///   - ledger: The `Ledger` whose accounts and splits will be considered.
    ///   - context: The `NSManagedObjectContext` used for fetches and object IDs.
    ///   - includeDescendants: When `true`, each account's `total` includes all descendants; when
    ///     `false`, `total` equals `own`.
    /// - Returns: A dictionary mapping `Account` object IDs to their `AccountBalance`.
    /// - Note: If the ledger has a `rootAccount`, aggregation starts there; otherwise, it starts
    ///   at all top-level accounts (those with `parent == nil`).
    static func computeBalances(
        ledger: Ledger,
        context: NSManagedObjectContext,
        includeDescendants: Bool
    ) throws -> [NSManagedObjectID: AccountBalance] {

        let accReq = Account.fetchRequest()
        accReq.predicate = NSPredicate(format: "ledger == %@", ledger)
        let accounts: [Account] = (try? context.fetch(accReq)) ?? []

        var childrenByParent: [NSManagedObjectID: [Account]] = [:]
        for a in accounts {
            if let p = a.parent {
                childrenByParent[p.objectID, default: []].append(a)
            }
        }

        let spReq = Split.fetchRequest()
        spReq.predicate = NSPredicate(format: "account.ledger == %@", ledger)
        let splits: [Split] = (try? context.fetch(spReq)) ?? []

        var ownByAcc: [NSManagedObjectID: Decimal] = [:]
        for sp in splits {
            guard let acc = sp.account else { continue }
            let amount = splitValue(sp)
            let signed = signedAmount(amount: amount, split: sp, account: acc)
            ownByAcc[acc.objectID, default: 0] += signed
        }

        var result: [NSManagedObjectID: AccountBalance] = [:]

        func dfs(_ acc: Account) -> Decimal {
            let own = ownByAcc[acc.objectID, default: 0]
            if !includeDescendants {
                result[acc.objectID] = .init(own: own, total: own)
                return own
            }

            let kids = (childrenByParent[acc.objectID] ?? []).sorted { ($0.code ?? "") < ($1.code ?? "") }
            let kidsTotal = kids.reduce(Decimal(0)) { $0 + dfs($1) }
            let total = own + kidsTotal
            result[acc.objectID] = .init(own: own, total: total)
            return total
        }

        if let root = ledger.rootAccount {
            _ = dfs(root)
        } else {
            for a in accounts where a.parent == nil { _ = dfs(a) }
        }

        return result
    }

    /// Converts a split's numerator/denominator into a `Decimal` amount.
    ///
    /// Treats a zero denominator as `1` to avoid division by zero.
    private static func splitValue(_ sp: Split) -> Decimal {
        let denom = sp.valueDenom == 0 ? 1 : sp.valueDenom
        return Decimal(sp.valueNum) / Decimal(denom)
    }

    /// Returns the signed amount for a split given the account's kind.
    ///
    /// Assumes `Split.side` uses `0` for debit and `1` for credit. Assets and expenses increase
    /// with debits and decrease with credits; liabilities, equity, and income do the opposite.
    private static func signedAmount(amount: Decimal, split: Split, account: Account) -> Decimal {
        let isDebit = (split.side == 0)

        switch account.kind {
        case AccountTypeKind.asset.rawValue,
             AccountTypeKind.expense.rawValue:
            return isDebit ? amount : -amount

        case AccountTypeKind.liability.rawValue,
             AccountTypeKind.equity.rawValue,
             AccountTypeKind.income.rawValue:
            return isDebit ? -amount : amount

        default:
            return isDebit ? amount : -amount
        }
    }
}
