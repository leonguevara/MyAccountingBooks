//
//  Account+Domain.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-25.
//

import Foundation
import CoreData

/// Account+Extensions
///
/// Convenience behaviors and helpers for the `Account` Core Data entity.

/// Extensions that configure default values on insert and provide convenience properties.
extension Account {
    /// Initializes default fields when an `Account` is first inserted into a context.
    ///
    /// Sets a new `UUID` for `id`, stamps `createdAt`, and initializes flags (`isActive`,
    /// `isPlaceholder`, and `accountRole`). The updates are performed on the entity's context
    /// via `context.perform` to ensure thread safety.
    public override nonisolated func awakeFromInsert() {
        super.awakeFromInsert()

        let newID = UUID()
        let now = Date()

        guard let context = self.managedObjectContext else { return }
        let oid = self.objectID

        // Perform updates on the context queue to respect Core Data threading.
        context.perform {
            guard let account = try? context.existingObject(with: oid) as? Account else { return }
            account.id = newID
            account.createdAt = now
            account.isActive = true
            account.isPlaceholder = false
            account.accountRole = 0
        }
    }

    /// Indicates whether this account is the root of its ledger.
    ///
    /// Returns true when the account has no parent and matches the ledger's `rootAccount`.
    var isRoot: Bool {
        parent == nil && ledger?.rootAccount == self
    }
}

/// Account+Tree
///
/// Convenience helpers for navigating an account's tree structure.
///
/// Provides sorted, array-backed accessors for an account's `children` relationship and a
/// variant that returns `nil` when there are no children, which is useful for views that
/// distinguish between leaf and non-leaf nodes (e.g., `OutlineGroup`).
extension Account {
    /// Returns the account's children as a sorted array.
    ///
    /// Children are sorted ascending by `code` (falling back to an empty string when `code` is
    /// `nil`). If you prefer a different ordering (e.g., by `name`), adjust the comparator here.
    /// When the underlying relationship is `nil`, this returns an empty array.
    var childrenArray: [Account] {
        let set = (children as? Set<Account>) ?? []
        return set.sorted {
            ($0.code ?? "") < ($1.code ?? "")
        }
    }
        
    /// Returns the account's children as an optional array for outline-style views.
    ///
    /// Returns `nil` when there are no children, which allows `OutlineGroup` and similar views
    /// to treat the node as a leaf without allocating an empty collection.
    var childrenArrayOptional: [Account]? {
        let arr = childrenArray
        return arr.isEmpty ? nil : arr
    }
}

/// Account+UI
///
/// UI conveniences for presenting `Account` classification values.
///
/// Provides human-readable display strings for an account's `kind` and `accountRole`. These
/// helpers centralize the mapping from stored raw values to localized (or user-facing)
/// labels suitable for lists, detail views, and reports.
extension Account {

    /// A human-readable label for the account's type (`kind`).
    ///
    /// Maps `AccountTypeKind` raw values to short display strings. Returns "Other" when the
    /// stored value does not match any known case.
    var kindDisplay: String {
        switch kind {
        case AccountTypeKind.asset.rawValue: return "Asset"
        case AccountTypeKind.liability.rawValue: return "Liability"
        case AccountTypeKind.equity.rawValue: return "Equity"
        case AccountTypeKind.income.rawValue: return "Income"
        case AccountTypeKind.expense.rawValue: return "Expense"
        default: return "Other"
        }
    }

    /// A human-readable label for the account's role (`accountRole`).
    ///
    /// Maps `AccountRole` raw values to concise display strings (e.g., "A/R", "A/P"). Returns
    /// "Other" when the stored value does not match any known case.
    var roleDisplay: String {
        switch accountRole {
        case AccountRole.asset.rawValue: return "Asset"
        case AccountRole.bank.rawValue: return "Bank"
        case AccountRole.cash.rawValue: return "Cash"
        case AccountRole.accountReceivable.rawValue: return "A/R"
        case AccountRole.mutualFund.rawValue: return "Mutual Fund"
        case AccountRole.stock.rawValue: return "Stock"
        case AccountRole.liability.rawValue: return "Liability"
        case AccountRole.creditCard.rawValue: return "Credit Card"
        case AccountRole.accountPayable.rawValue: return "A/P"
        case AccountRole.equity.rawValue: return "Equity"
        case AccountRole.income.rawValue: return "Income"
        case AccountRole.expense.rawValue: return "Expense"
        default: return "Other"
        }
    }
}
