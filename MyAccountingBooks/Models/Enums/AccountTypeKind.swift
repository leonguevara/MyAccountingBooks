//
//  AccountTypeKind.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-09.
//

/// A canonical set of account categories used in double-entry accounting.
///
/// `AccountTypeKind` classifies ledger accounts into five fundamental types.
/// The raw value (`Int16`) can be used for persistence or interop with
/// storage layers that expect numeric codes.
///
/// The cases are ordered and stable; do not renumber existing values
/// without providing a migration path for stored data.
enum AccountTypeKind: Int16, CaseIterable {
    /// Resources owned by the entity (cash, inventory, receivables).
    case asset = 1
    /// Obligations owed to others (loans, payables).
    case liability
    /// Owner's residual interest (capital, retained earnings).
    case equity
    /// Inflows that increase equity (revenue, gains).
    case income
    /// Outflows that decrease equity (costs, losses).
    case expense
}
