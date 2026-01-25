//
//  COAAccountDTO.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-13.
//

import Foundation

/// A data transfer object representing a Chart of Accounts (COA) entry
/// decoded from bundled JSON.
///
/// This structure mirrors the fields expected in seed/bootstrap files and
/// is intended for import/migration tasks rather than runtime domain logic.
/// All fields correspond directly to JSON keys with the same name unless
/// noted otherwise.
struct COAAccountDTO: Decodable {
    /// Unique account code within the COA (e.g., "1000").
    let code: String
    
    /// Optional parent account code for hierarchical COA structures.
    let parentCode: String?
    
    /// Human-readable account name.
    let name: String
    
    /// Depth level in the COA hierarchy (root starts at 0 or 1 depending on data).
    let level: Int

    /// Raw value of `AccountTypeKind` (1...5). Used to derive the fundamental
    /// accounting type (asset, liability, equity, income, expense).
    let kind: Int16
    
    /// Raw value of `AccountRole` (1...12). Stored as the account's role for
    /// finer classification (e.g., bank, cash, creditCard).
    let role: Int16
    
    /// Optional free-form notes carried in the source JSON.
    let notes: String?
    
    /// Optional flag indicating a non-postable placeholder account used only
    /// to organize the hierarchy.
    let isPlaceholder: Bool?
}

