//
//  AccountsTreeGnuCashView.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-11.
//

import SwiftUI
import CoreData

struct AccountsTreeGnuCashView: View {
    @Environment(\.managedObjectContext) private var moc

    let ledger: Ledger

    @State private var balances: [NSManagedObjectID: AccountBalance] = [:]
    @State private var showTotals: Bool = true
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            headerBar

            Divider()

            if let root = ledger.rootAccount {
                OutlineGroup([root], children: \.childrenArrayOptional) { account in
                    row(account)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
            } else {
                ContentUnavailableView(
                    "Sin cuentas",
                    systemImage: "list.bullet.indent",
                    description: Text("No se encontró la cuenta raíz.")
                )
            }
        }
        .navigationTitle("Cuentas")
        .task { await loadBalances() }
        .alert("Error", isPresented: Binding(get: { errorMessage != nil }, set: { _ in errorMessage = nil })) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var headerBar: some View {
        HStack(spacing: 12) {
            Toggle("Mostrar totales (incluye hijos)", isOn: $showTotals)
                .toggleStyle(.switch)
                .onChange(of: showTotals) { _, _ in
                    Task { await loadBalances() }
                }

            Spacer()

            if balances.isEmpty {
                ProgressView().controlSize(.small)
            }
        }
        .padding(12)
    }

    @ViewBuilder
    private func row(_ account: Account) -> some View {
        HStack(spacing: 12) {
            // Col 1: Cuenta (con indent automático del OutlineGroup)
            HStack(spacing: 8) {
                Image(systemName: account.isPlaceholder ? "folder" : "doc.text")
                    .foregroundStyle(.secondary)

                Text(account.name ?? "Sin nombre")
                    .lineLimit(1)
            }
            .frame(minWidth: 280, maxWidth: .infinity, alignment: .leading)

            // Col 2: Tipo/Rol
            Text(account.accountTypeDisplay)
                .foregroundStyle(.secondary)
                .frame(width: 110, alignment: .leading)

            // Col 3: Descripción (si tienes)
            Text(account.accountDescription ?? "")
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(minWidth: 220, maxWidth: .infinity, alignment: .leading)

            // Col 4: Balance
            Text(formatMoney(balance(for: account)))
                .font(.system(.body, design: .monospaced))
                .frame(width: 140, alignment: .trailing)
        }
        .padding(.vertical, 3)
    }

    private func balance(for account: Account) -> Decimal {
        let b = balances[account.objectID]
        return showTotals ? (b?.total ?? 0) : (b?.own ?? 0)
    }

    private func formatMoney(_ value: Decimal) -> String {
        // Puedes meter moneda del ledger aquí (por ahora simple)
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.currencyCode = ledger.currencyCommodity?.mnemonic ?? "MXN"
        nf.maximumFractionDigits = 2
        nf.minimumFractionDigits = 2
        return nf.string(from: value as NSDecimalNumber) ?? "\(value)"
    }

    private func loadBalances() async {
        do {
            let computed = try moc.performAndWait {
                try AccountBalanceService.computeBalances(
                    ledger: ledger,
                    context: moc,
                    includeDescendants: showTotals
                )
            }
            balances = computed
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
