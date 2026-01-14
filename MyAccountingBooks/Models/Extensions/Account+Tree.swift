//
//  Account+Tree.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-12.
//

import Foundation

extension Account {
    /// Útil para el OutlineGroup (requiere Optional)
    var childrenArrayOptional: [Account]? {
        let arr = childrenArray
        return arr.isEmpty ? nil : arr
    }
    
    /// Ordena por código (o por nombre si prefieres)
    var childrenArray: [Account] {
        let set = children as? Set<Account> ?? []
        return set.sorted {
            ($0.code ?? "") < ($1.code ?? "")
        }
    }
}
