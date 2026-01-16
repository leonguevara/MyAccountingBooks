//
//  AccountRole.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-15.
//

/// A finer-grained classification for individual accounts within a chart of accounts.
///
/// While `AccountTypeKind` captures the fundamental accounting type, `AccountRole`
/// distinguishes specific roles like bank, cash, or credit card to support
/// domain logic and UI. The raw value (`Int16`) is suitable for persistence
/// where compact numeric codes are preferred.
///
/// The numeric values are intended to be stable. Avoid renumbering existing
/// cases without a data migration strategy.
enum AccountRole: Int16, CaseIterable {
    /// Generic asset account when no more specific role applies.
    case asset = 1
    /// Bank deposit accounts (checking, savings).
    case bank
    /// Physical cash on hand (petty cash, till).
    case cash
    /// Trade receivables owed by customers.
    case accountReceivable
    /// Investment accounts holding mutual funds.
    case mutualFund
    /// Investment accounts holding individual equities.
    case stock
    /// Generic liability when no more specific role applies.
    case liability
    /// Credit card accounts representing revolving debt.
    case creditCard
    /// Trade payables owed to vendors.
    case accountPayable
    /// Owner's equity accounts (capital, retained earnings).
    case equity
    /// Revenue accounts for inflows that increase equity.
    case income
    /// Expense accounts for outflows that reduce equity.
    case expense
}

