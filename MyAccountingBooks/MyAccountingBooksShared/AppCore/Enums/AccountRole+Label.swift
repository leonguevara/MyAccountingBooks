//
//  AccountRole+Label.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-18.
//

//

import Foundation

/// UI helpers for `AccountRole`.
extension AccountRole {

    /// A concise, human-readable label for displaying the role in UI.
    ///
    /// - Note: Update the switch cases to match your actual `AccountRole` cases and provide
    ///         localized strings as appropriate. The `@unknown default` returns an em dash
    ///         to gracefully handle future enum cases.
    var label: String {
        switch self {

        // Ejemplos típicos (ajusta a tus casos reales):
        case .asset:                return "Asset"
        case .bank:                 return "Bank"
        case .cash:                 return "Cash"
        case .accountReceivable:    return "A/Receivable"
        case .mutualFund:           return "Mutual Fund"
        case .stock:                return "Stock"
        case .liability:            return "Liability"
        case .creditCard:           return "Credit Card"
        case .accountPayable:       return "A/Payable"
        case .equity:               return "Equity"
        case .income:               return "Income"
        case .expense:              return "Expense"

        // Fallback for any future/unknown roles.
        @unknown default:
            return "—"
        }
    }
}
