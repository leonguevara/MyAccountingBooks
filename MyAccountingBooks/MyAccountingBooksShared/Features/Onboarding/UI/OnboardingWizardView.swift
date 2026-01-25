//
//  OnboardingWizardView.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-08.
//

import SwiftUI

struct OnboardingWizardView: View {
    var onCancel: () -> Void
    var onFinished: () -> Void
    
    @Environment(\.managedObjectContext) private var moc

    @State private var ownerName: String = "Usuario principal"
    @State private var ledgerName: String = "Mi libro"
    @State private var currencyMnemonic: String = "MXN" // si luego soportas multi-moneda, aquí lo extiendes

    @State private var isWorking = false
    @State private var errorMessage: String?
    
    // Para saber si ya hay libros
    @FetchRequest(
        entity: Ledger.entity(),
        sortDescriptors: []
    )
    private var ledgers: FetchedResults<Ledger>

    @State private var showCancelAlert = false

    var body: some View {
        VStack(spacing: 18) {
            Text("Configuración inicial")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Aquí haremos preguntas para crear tu primer libro (Owner + Ledger + moneda + SAT/NIIF).")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Form {
                Section("Propietario") {
                    TextField("Nombre del propietario", text: $ownerName)
                        .textFieldStyle(.roundedBorder)
                }
                
                Section("Libro") {
                    TextField("Nombre del libro", text: $ledgerName)
                        .textFieldStyle(.roundedBorder)
                }
                
                Section("Moneda") {
                    TextField(
                        "Moneda (mnemonic (MXN, USD, etc.))",
                        text: Binding(
                            get: { currencyMnemonic },
                            set: {
                                let cleaned = $0.uppercased().replacingOccurrences(of: " ", with: "")
                                currencyMnemonic = String(cleaned.prefix(3))
                            }
                        )
                    )
                    .textFieldStyle(.roundedBorder)
                }
            }
            .formStyle(.grouped)
            .frame(maxHeight:320)
            .padding(.horizontal, 24)
            
            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            HStack {
                Button("Cancelar") {
                    if ledgers.isEmpty {
                        showCancelAlert = true
                    } else {
                        onCancel()
                    }
                }
                .keyboardShortcut(.cancelAction)
                .disabled(isWorking)
                .alert("No puedes continuar", isPresented: $showCancelAlert) {
                    Button("Entendido", role: .cancel) { }
                } message: {
                    Text("Debes crear al menos un libro contable para poder usar la aplicación.")
                }
                
                Spacer()
                
                Button {
                    Task { await createFirstBook() }
                } label: {
                    if isWorking {
                        ProgressView().scaleEffect(0.9)
                    } else {
                        Text("Crear primer libro")
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(isWorking)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .padding(.top, 24)
        .frame(minWidth: 640, minHeight: 520)
    }
    
    @MainActor
    private func createFirstBook() async {
        errorMessage = nil
        isWorking = true
        defer { isWorking = false }
        
        let trimmedOwner = ownerName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLedger = ledgerName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCurrency = currencyMnemonic.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        guard !trimmedOwner.isEmpty else {
            errorMessage = "Escribe un nombre para el propietario."
            return
        }
        guard !trimmedLedger.isEmpty else {
            errorMessage = "Escribe un nombre para el libro."
            return
        }
        guard !trimmedCurrency.isEmpty else {
            errorMessage = "Escribe la moneda (por ejemplo: MXN)."
            return
        }
        
        do {
            try await runBootstrap(ownerName: trimmedOwner, ledgerName: trimmedLedger, currencyMnemonic: trimmedCurrency)
            onFinished()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    /// Corre el bootstrap + importa el catálogo desde chart_of_accounts.json
    private func runBootstrap(ownerName: String, ledgerName: String, currencyMnemonic: String) async throws {
        
        try await moc.perform {
            // 1) Bootstrap base (Owner + currency + account types + ledger + rootAccount)
            let result = try BootstrapService.createFirstLedger(
                context: moc,
                ownerDisplayName: ownerName,
                ledgerName: ledgerName,
                currencyMnemonic: currencyMnemonic
            )
            
            // 2) Importar catálogo desde JSON
            try ChartOfAccountsJSONImporter.importFromBundledJSON(
                into: result.ledger,
                context: moc,
                resourceName: "chart_of_accounts"
            )
            
            // 3) Guardar
            if moc.hasChanges {
                try moc.save()
            }
        }
    }
}
