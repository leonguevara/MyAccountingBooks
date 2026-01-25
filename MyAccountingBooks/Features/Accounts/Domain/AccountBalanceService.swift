//
//  AccountBalanceService.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-11.
//

/// AccountBalanceService
///
/// Computes and exposes account balances for a given `Ledger` using Core Data.
///
/// Responsibilities:
/// - Fetch `Split` entries for a ledger and compute direct balances per account.
/// - Aggregate hierarchical totals by traversing the account tree.
/// - Publish the latest computed balances and any error encountered.
//

import Foundation
import CoreData
import Combine

/// A main-actor service that calculates and publishes balances for accounts in a `Ledger`.
///
/// Use `recompute(in:context:)` to refresh balances from persistent `Split`s. Direct balances are
/// computed per account, while `totalBalance(for:balances:)` recursively sums a node and its children
/// to provide hierarchical totals.
@MainActor
final class AccountBalanceService: ObservableObject {

    /// Container for balance maps computed for a single ledger.
    ///
    /// - Note: `direct` contains the per-account signed amount derived from splits only for that account.
    struct LedgerBalances {
        /// Map of `Account.objectID` to its direct (non-aggregated) balance.
        var direct: [NSManagedObjectID: Decimal] = [:]
    }

    /// The most recently computed balances. Updated when `recompute(in:context:)` succeeds.
    @Published private(set) var lastBalances: LedgerBalances = .init()

    /// A user-facing error description if the last recompute failed; `nil` on success.
    @Published private(set) var lastErrorMessage: String?

    /// Recomputes balances for the given ledger and updates published properties.
    ///
    /// - Parameters:
    ///   - ledger: The ledger whose splits should be analyzed.
    ///   - context: The Core Data context used to fetch splits.
    /// - Note: Runs on the main actor; heavy work should be offloaded if the dataset is large.
    func recompute(in ledger: Ledger, context: NSManagedObjectContext) {
        do {
            let balances = try Self.computeDirectBalances(in: ledger, context: context)
            self.lastBalances = balances
            self.lastErrorMessage = nil
        } catch {
            self.lastErrorMessage = error.localizedDescription
        }
    }

    // MARK: - Pure functions (static)

    /// Computes direct balances per account by summing signed split amounts.
    ///
    /// Fetches all `Split` objects for the specified `ledger`, interprets `side` as
    /// 0 = debit (positive) and 1 = credit (negative), and accumulates results in a map.
    ///
    /// - Parameters:
    ///   - ledger: The ledger that owns the splits to analyze.
    ///   - context: The Core Data context used for fetching.
    /// - Returns: A `LedgerBalances` value containing the direct balance map.
    /// - Throws: Any fetch error encountered by the context.
    static func computeDirectBalances(
        in ledger: Ledger,
        context: NSManagedObjectContext
    ) throws -> LedgerBalances {

        // Prepare a fetch request for all splits belonging to the provided ledger.
        let fr = NSFetchRequest<Split>(entityName: "Split")
        fr.predicate = NSPredicate(format: "transaction.ledger == %@", ledger)
        fr.returnsObjectsAsFaults = false

        // Avoid faults to speed up iteration when only reading values.
        
        let splits = try context.fetch(fr)

        // Accumulator for per-account direct balances.
        var out = LedgerBalances()

        for s in splits {
            guard let a = s.account else { continue }
            let amt = decimalAmount(valueNum: s.valueNum, valueDenom: Int64(s.valueDenom))

            // Interpret side: 0 = debit (positive), 1 = credit (negative).
            let signed = (s.side == 0) ? amt : -amt
            out.direct[a.objectID, default: 0] += signed
        }

        return out
    }

    /// Computes the hierarchical total for an account by summing its direct balance and all descendants.
    ///
    /// - Parameters:
    ///   - account: The root account to total.
    ///   - balances: A previously computed `LedgerBalances` with direct amounts.
    /// - Returns: The aggregated balance for the account subtree.
    static func totalBalance(
        for account: Account,
        balances: LedgerBalances
    ) -> Decimal {
        var sum = balances.direct[account.objectID, default: 0]

        if let children = account.children as? Set<Account>, !children.isEmpty {
            for c in children {
                sum += totalBalance(for: c, balances: balances)
            }
        }
        return sum
    }

    /// Converts a rational amount (valueNum/valueDenom) into a Decimal.
    ///
    /// - Parameters:
    ///   - valueNum: The numerator component.
    ///   - valueDenom: The denominator component. If zero, returns 0 to avoid division by zero.
    /// - Returns: The decimal result of the fraction or zero when denominator is zero.
    private static func decimalAmount(valueNum: Int64, valueDenom: Int64) -> Decimal {
        guard valueDenom != 0 else { return 0 }
        return Decimal(valueNum) / Decimal(valueDenom)
    }
    
    /// Aplica el estilo "GnuCash-like" al BALANCE mostrado.
    /// En contabilidad, típicamente pasivos/capital/ingresos se muestran con signo invertido
    /// vs el acumulado "natural" del motor.
    static func displayBalanceGnuCashStyle(kind: Any?, rawBalance: Decimal) -> Decimal {

        // Caso 2: si `kind` viene como Int16 (si guardas enum como entero)
        if let n = kind as? Int16, let k = AccountTypeKind(rawValue: n) {
            return displayBalanceGnuCashStyle(kind: k, rawBalance: rawBalance)
        }

        // Fallback: si no sabemos el tipo, no tocamos el signo.
        return rawBalance
    }
}

