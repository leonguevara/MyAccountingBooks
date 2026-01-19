//
//  AppShellView.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-08.
//

/*import SwiftUI

struct AppShellView: View {
    var body: some View {
        NavigationSplitView {
            SidebarView()
        } detail: {
            Text("Selecciona un Ledger")
                .foregroundStyle(.secondary)
        }
    }
}*/

import SwiftUI
import CoreData

struct AppShellView: View {
    @Environment(\.managedObjectContext) private var moc

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Ledger.createdAt, ascending: true)]
    )
    private var ledgers: FetchedResults<Ledger>

    @State private var selectedLedger: Ledger?
    @State private var resetError: String?
    @State private var showResetAlert = false

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedLedger) {
                Section("Libros") {
                    ForEach(ledgers) { ledger in
                        Text(ledger.name ?? "Sin nombre")
                            .tag(ledger as Ledger?)
                    }
                }
            }
            .frame(minWidth: 220)
            .navigationTitle("MyAccountingBooks")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(role: .destructive) {
                        do {
                            try PersistenceController.shared.resetLocalStore()
                        } catch {
                            resetError = error.localizedDescription
                            showResetAlert = true
                        }
                    } label: {
                        Label("Reset local", systemImage: "trash")
                    }
                }
            }
            .alert("No se pudo resetear", isPresented: $showResetAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(resetError ?? "Error desconocido")
            }
        } content: {
            if let ledger = selectedLedger ?? ledgers.first {
                AccountsTreeGnuCashView(ledger: ledger)
                // LedgerAccountsDebugView(ledger: ledger)
            } else {
                ContentUnavailableView(
                    "Sin libros",
                    systemImage: "book.closed",
                    description: Text("Crea un libro para comenzar.")
                )
            }
        } detail: {
            ContentUnavailableView(
                "Detalle",
                systemImage: "doc.plaintext",
                description: Text("Selecciona una cuenta para ver su detalle.")
            )
        }
        .onAppear {
            selectedLedger = selectedLedger ?? ledgers.first
        }
    }
}

