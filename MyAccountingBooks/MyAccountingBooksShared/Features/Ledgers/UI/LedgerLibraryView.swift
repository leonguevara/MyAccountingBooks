//
//  LedgerLibraryView.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-24.
//
//  Lista + acciones: abrir / cerrar / inactivar (solo lectura) / borrar / crear
//

import SwiftUI
import CoreData

struct LedgerLibraryView: View {
    @Environment(\.managedObjectContext) private var moc
    @EnvironmentObject private var session: AppSession

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Ledger.createdAt, ascending: true)],
        animation: .default
    )
    private var ledgers: FetchedResults<Ledger>

    @State private var showCreate = false
    @State private var showDeleteConfirm = false
    @State private var pendingDelete: Ledger?
    @State private var errorMessage: String?

    /// Opcional: si quieres que al abrir un ledger, se cierre esta pantalla automáticamente.
    let dismissOnOpen: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
                    .padding(.top, 8)
            }

            List {
                Section("Libros") {
                    if ledgers.isEmpty {
                        ContentUnavailableView(
                            "Sin libros",
                            systemImage: "book.closed",
                            description: Text("Crea tu primer libro para comenzar.")
                        )
                        .padding(.vertical, 24)
                    } else {
                        ForEach(ledgers) { ledger in
                            row(ledger)
                        }
                    }
                }
            }
        }
        .navigationTitle("Biblioteca de libros")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showCreate = true
                } label: {
                    Label("Crear libro", systemImage: "plus")
                }
            }

            ToolbarItem(placement: .automatic) {
                if session.activeLedgerID != nil {
                    Button {
                        LedgerService.closeActiveLedger(session: session)
                    } label: {
                        Label("Cerrar libro", systemImage: "xmark.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showCreate) {
            LedgerCreateSheet(openAfterCreate: true)
                .environment(\.managedObjectContext, moc)
                .environmentObject(session)
        }
        .alert("¿Borrar libro?", isPresented: $showDeleteConfirm) {
            Button("Cancelar", role: .cancel) { pendingDelete = nil }
            Button("Borrar", role: .destructive) { confirmDelete() }
        } message: {
            Text("Esta acción no se puede deshacer.")
        }
        .frame(minWidth: 520, minHeight: 420)
    }

    @ViewBuilder
    private func row(_ ledger: Ledger) -> some View {
        let isActive = (ledger.id != nil && ledger.id == session.activeLedgerID)

        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(ledger.name ?? "(Sin nombre)")
                        .font(.headline)

                    if isActive {
                        Text("ABIERTO")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.green.opacity(0.15))
                            .clipShape(Capsule())
                    }

                    if !ledger.isActive {
                        Text("SOLO LECTURA")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.orange.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }

                Text("\(ledger.currencyCode ?? "—") · \(ledger.precision) decimales")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                open(ledger)
            } label: {
                Text(isActive ? "Ver" : "Abrir")
            }
            .buttonStyle(.bordered)
            .disabled(ledger.isActive != true ? false : false) // abrir permitido aun en read-only

        }
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                open(ledger)
            } label: {
                Label("Abrir", systemImage: "folder")
            }

            if isActive {
                Button {
                    LedgerService.closeActiveLedger(session: session)
                } label: {
                    Label("Cerrar libro", systemImage: "xmark.circle")
                }
            }

            Button {
                toggleReadOnly(ledger)
            } label: {
                Label(!ledger.isActive ? "Activar (editable)" : "Inactivar (solo lectura)",
                      systemImage: !ledger.isActive ? "pencil" : "lock")
            }

            Divider()

            Button(role: .destructive) {
                pendingDelete = ledger
                showDeleteConfirm = true
            } label: {
                Label("Borrar", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing) {
            Button {
                toggleReadOnly(ledger)
            } label: {
                Label("Solo lectura", systemImage: "lock")
            }
            .tint(.orange)

            Button(role: .destructive) {
                pendingDelete = ledger
                showDeleteConfirm = true
            } label: {
                Label("Borrar", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                open(ledger)
            } label: {
                Label("Abrir", systemImage: "folder")
            }
            .tint(.blue)
        }
    }

    // MARK: - Actions

    private func open(_ ledger: Ledger) {
        errorMessage = nil
        guard let id = ledger.id else { return }
        session.openLedger(id: id)
        if dismissOnOpen { dismiss() }
    }

    private func toggleReadOnly(_ ledger: Ledger) {
        errorMessage = nil
        do {
            try LedgerService.toggleArchived(ledger, context: moc)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func confirmDelete() {
        errorMessage = nil
        guard let ledger = pendingDelete else { return }
        do {
            try LedgerService.deleteLedger(
                ledger,
                activeLedgerID: session.activeLedgerID,
                context: moc
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        pendingDelete = nil
    }
}
