//
//  AccountsTreeView.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-12.
//

import SwiftUI
import CoreData

struct AccountsTreeView: View {
    @Environment(\.managedObjectContext) private var moc

    let ledger: Ledger

    @FetchRequest private var rootAccounts: FetchedResults<Account>

    init(ledger: Ledger) {
        self.ledger = ledger

        // Nota: rootAccount normalmente es una sola, pero lo tratamos como fetch
        // para refresco automático + compatibilidad con cambios.
        _rootAccounts = FetchRequest<Account>(
            sortDescriptors: [
                NSSortDescriptor(keyPath: \Account.code, ascending: true)
            ],
            predicate: NSPredicate(format: "ledger == %@ AND parent == nil", ledger)
        )
    }

    var body: some View {
        Group {
            if let root = ledger.rootAccount {
                OutlineGroup([root], children: \.childrenArrayOptional) { account in
                    AccountRow(account: account)
                }
                .padding(.vertical, 8)
            } else if let firstRoot = rootAccounts.first {
                OutlineGroup([firstRoot], children: \.childrenArrayOptional) { account in
                    AccountRow(account: account)
                }
                .padding(.vertical, 8)
            } else {
                ContentUnavailableView(
                    "Sin cuentas",
                    systemImage: "list.bullet.indent",
                    description: Text("No se encontraron cuentas para este libro.")
                )
            }
        }
        .navigationTitle("Cuentas")
    }
}

private struct AccountRow: View {
    let account: Account

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: account.isPlaceholder ? "folder" : "doc.text")
                .foregroundStyle(account.isPlaceholder ? .secondary : .primary)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(account.code ?? "")
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundStyle(.secondary)

                    Text(account.name ?? "Sin nombre")
                        .font(.body)
                }
            }
            Spacer()
        }
        .padding(.vertical, 2)
    }
}
