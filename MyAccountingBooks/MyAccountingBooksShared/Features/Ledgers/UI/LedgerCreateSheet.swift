//
//  LedgerCreateSheet.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-24.
//

import SwiftUI
import CoreData

struct LedgerCreateSheet: View {
    @Environment(\.managedObjectContext) private var moc
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: AppSession

    // Inputs
    @State private var name: String = ""
    @State private var currencyCode: String = "MXN"
    @State private var precision: Int = 2

    // UI state
    @State private var isWorking = false
    @State private var errorMessage: String?

    /// Si true, al crear se “abre” en la sesión.
    let openAfterCreate: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("Nuevo libro") {
                    TextField("Nombre del libro", text: $name)

                    TextField("Moneda (ISO)", text: $currencyCode)
                    #if os(iOS)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                    #endif
                        .onChange(of: currencyCode) { _, newValue in
                            let filtered = newValue.uppercased()
                                .filter { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }
                            if filtered != newValue { currencyCode = filtered }
                        }

                    Stepper("Decimales: \(precision)", value: $precision, in: 0...6)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Crear libro")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                        .disabled(isWorking)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Crear") { create() }
                        .disabled(isWorking)
                }
            }
        }
        .frame(minWidth: 420, minHeight: 280)
    }

    private func create() {
        errorMessage = nil
        isWorking = true

        do {
            let ledger = try LedgerService.createLedger(
                name: name,
                currencyCode: currencyCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(),
                precision: Int16(precision),
                context: moc
            )

            if openAfterCreate {
                session.openLedger(ledger)
            }

            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isWorking = false
    }
}
