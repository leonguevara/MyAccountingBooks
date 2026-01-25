//
//  AppShellView.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-08.
//



import SwiftUI
import CoreData

struct AppShellView: View {
    @Environment(\.managedObjectContext) private var moc
    @EnvironmentObject private var session: AppSession

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Ledger.createdAt, ascending: true)],
        animation: .default
    )
    private var ledgers: FetchedResults<Ledger>

    @State private var selectedLedger: Ledger?
    @State private var resetError: String?
    @State private var showResetAlert = false
    
    private var currentLedger: Ledger? {
        selectedLedger ?? session.resolveActiveLedger(in: moc)
    }

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
            .onChange(of: selectedLedger) { _, newValue in
                if let ledger = newValue {
                    session.openLedger(ledger)
                } else {
                    session.closeLedger()
                }
            }
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
                ToolbarItem(placement: .automatic) {
                    /*Button("Cerrar libro") {
                        selectedLedger = nil
                        session.closeLedger()
                    }
                    .disabled((session.resolveActiveLedger(in: moc) == nil) && (selectedLedger == nil))*/
                    Button("Cerrar libro") {
                        // Cerrar = sesión + UI
                        session.closeLedger()
                        selectedLedger = nil
                    }
                    .disabled(currentLedger == nil)
                }
            }
            .alert("No se pudo resetear", isPresented: $showResetAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(resetError ?? "Error desconocido")
            }
        } content: {
            // ✅ sin auto-reopen
            /*let active = session.resolveActiveLedger(in: moc)
            let current = selectedLedger ?? active*/

            if let ledger = currentLedger {
                AccountsTreeGnuCashView(ledger: ledger)
            } else if ledgers.isEmpty {
                ContentUnavailableView(
                    "Sin libros",
                    systemImage: "book.closed",
                    description: Text("Crea un libro para comenzar.")
                )
            } else {
                ContentUnavailableView(
                    "Elige un libro",
                    systemImage: "book",
                    description: Text("Selecciona un libro en la barra lateral.")
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
            // ✅ Solo reflejar la sesión si existe; NO elegir ledgers.first
            if selectedLedger == nil, let open = session.resolveActiveLedger(in: moc) {
                selectedLedger = open
            }
        }
        .onChange(of: session.activeLedgerID) { _, _ in
            // Sesión -> UI cuando cambie por fuera
            let open = session.resolveActiveLedger(in: moc)
            
            // Evita loops: solo actualiza si realmente cambió
            if selectedLedger?.objectID != open?.objectID {
                selectedLedger = open
            }
        }
    }
}

