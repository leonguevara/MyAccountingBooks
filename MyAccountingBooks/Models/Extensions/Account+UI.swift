//
//  Account+UI.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-11.
//

import Foundation

extension Account {
    var accountTypeDisplay: String {
        // Ajusta mapping según tu catálogo (kind Int16)
        let k = accountType?.kind ?? -1
        switch k {
        case 0: return "Asset"
        case 1: return "Liability"
        case 2: return "Equity"
        case 3: return "Income"
        case 4: return "Expense"
        default: return "Other"
        }
    }

    /// Si tu modelo tiene descripción como atributo distinto, ajusta el nombre aquí
    var accountDescription: String? {
        // Cambia "accountDescription" por el nombre real si ya existe.
        // Si no tienes descripción, regresa nil.
        nil
    }
}
