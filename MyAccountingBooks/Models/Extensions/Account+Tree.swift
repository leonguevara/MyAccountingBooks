//
//  Account+Tree.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-12.
//

import Foundation

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

