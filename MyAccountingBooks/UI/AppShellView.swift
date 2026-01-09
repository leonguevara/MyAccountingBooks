//
//  AppShellView.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-08.
//

import SwiftUI

struct AppShellView: View {
    var body: some View {
        NavigationSplitView {
            SidebarView()
        } detail: {
            Text("Selecciona un Ledger")
                .foregroundStyle(.secondary)
        }
    }
}
