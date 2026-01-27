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
    @State private var showCreateLedgerSheet = false
    
    private var currentLedger: Ledger? {
        selectedLedger ?? session.resolveActiveLedger(in: moc)
    }

    var body: some View {
        NavigationSplitView {
            sidebar
        } content: {
            contentView
        } detail: {
            detailView
        }
        .onAppear {
            syncFromSession()
        }
        .onChange(of: session.activeLedgerID) { _, _ in
            syncFromSession()
        }
        .onChange(of: selectedLedger) { _, newValue in
            if let ledger = newValue {
                session.openLedger(ledger)
            } else {
                session.closeLedger()
            }
        }
        .alert("No se pudo resetear", isPresented: $showResetAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(resetError ?? "Error desconocido")
        }
        .sheet(isPresented: $showCreateLedgerSheet) {
            // Asegúrate de que LedgerCreateSheet use el moc por Environment
            LedgerCreateSheet(openAfterCreate: true)
                .environment(\.managedObjectContext, moc)
                .environmentObject(session)
        }
        .toolbar {
            toolbarContent
        }
    }
    
    private var sidebar: some View {
        // Opción 1 (recomendada): LedgerLibraryView recibe el binding de selección
        LedgerLibraryView(selection: $selectedLedger)
            .navigationTitle("MyAccountingBooks")
            .frame(minWidth: 240)

        /*
        // Opción 2: si tu LedgerLibraryView NO tiene `selection:`, usa callbacks:
        LedgerLibraryView(
            onOpen: { ledger in
                selectedLedger = ledger
                if let id = ledger.id { session.openLedger(id) }
            },
            onClose: {
                selectedLedger = nil
                session.closeLedger()
            }
        )
        */
        
        /*
        // Opción 3:
        List(selection: $selectedLedger) {
            Section("Libros") {
                ForEach(ledgers) { ledger in
                    HStack(spacing: 8) {
                        Text(ledger.name ?? "Sin nombre")
                        Spacer()
                        // Marca el activo en sesión (si quieres)
                        if let id = ledger.id, id == session.activeLedgerID {
                            Image(systemName: "checkmark.circle.fill")
                                .imageScale(.small)
                        }
                        // Opcional: mostrar archivado vía isActive inverso
                        if ledger.isActive == false {
                            Image(systemName: "archivebox")
                                .imageScale(.small)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tag(ledger as Ledger?)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("MyAccountingBooks")
        */
    }
    
    private var contentView: some View {
        Group {
            if let ledger = currentLedger {
                AccountsTreeGnuCashView(ledger: ledger)
            } else {
                ContentUnavailableView(
                    "Elige un libro",
                    systemImage: "book",
                    description: Text("Selecciona un libro en la barra lateral.")
                )
            }
        }
    }
    
    // MARK: - Detail

    private var detailView: some View {
        ContentUnavailableView(
            "Detalle",
            systemImage: "doc.plaintext",
            description: Text("Selecciona una cuenta para ver su detalle.")
        )
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        // Reset local (destructivo)
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

        // Crear libro
        ToolbarItem(placement: .automatic) {
            Button {
                showCreateLedgerSheet = true
            } label: {
                Label("Nuevo libro", systemImage: "plus")
            }
        }

        // Cerrar libro (no auto-reopen)
        ToolbarItem(placement: .automatic) {
            Button("Cerrar libro") {
                session.closeLedger()
                selectedLedger = nil
            }
            .disabled(currentLedger == nil)
        }
    }
    
    // MARK: - Sync

    /// Mantiene coherente:
    /// - session.activeLedgerID  <-> selectedLedger (UI)
    private func syncFromSession() {
        // 1) Si sesión tiene activo, reflejarlo en UI
        if let active = session.resolveActiveLedger(in: moc) {
            if selectedLedger?.objectID != active.objectID {
                selectedLedger = active
            }
            return
        }

        // 2) Si sesión NO tiene activo, NO auto-seleccionar nada.
        //    (Esto es lo que permite “Cerrar libro”.)
        if session.activeLedgerID == nil {
            // Si UI tiene algo seleccionado pero sesión dice nil, limpiamos UI
            if selectedLedger != nil {
                selectedLedger = nil
            }
        }
    }

}

