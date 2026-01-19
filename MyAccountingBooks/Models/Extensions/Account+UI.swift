//
//  Account+UI.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-11.
//

import Foundation

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
