//
//  SidebarView.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-08.
//

import SwiftUI

struct SidebarView: View {
    var body: some View {
        List {
            Section("Libros") {
                Text("Ledger 1 (placeholder)")
            }
            Section("Navegación") {
                Text("Cuentas")
                Text("Transacciones")
                Text("Programadas")
                Text("Payees")
                Text("Reportes")
            }
        }
        .navigationTitle("MyAccountingBooks")
    }
}
