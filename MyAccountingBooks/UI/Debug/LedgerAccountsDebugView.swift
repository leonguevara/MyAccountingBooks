//
//  LedgerAccountsDebugView.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-12.
//

import SwiftUI
import CoreData

struct LedgerAccountsDebugView: View {
    @Environment(\.managedObjectContext) private var moc
    let ledger: Ledger

    @FetchRequest private var all: FetchedResults<Account>
    @FetchRequest private var orphans: FetchedResults<Account>

    init(ledger: Ledger) {
        self.ledger = ledger

        _all = FetchRequest(
            sortDescriptors: [NSSortDescriptor(key: "code", ascending: true)],
            predicate: NSPredicate(format: "ledger == %@", ledger),
            animation: .default
        )

        _orphans = FetchRequest(
            sortDescriptors: [NSSortDescriptor(key: "code", ascending: true)],
            predicate: NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "ledger == %@", ledger),
                NSPredicate(format: "parent == nil"),
                NSPredicate(format: "SELF != %@", ledger.rootAccount ?? Account())
            ]),
            animation: .default
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Total cuentas en ledger: \(all.count)")
            Text("Cuentas sin parent (huérfanas): \(orphans.count)")

            List {
                Section("Huérfanas (muestra 50)") {
                    ForEach(orphans.prefix(50), id: \.objectID) { a in
                        VStack(alignment: .leading) {
                            Text("\(a.code ?? "(sin code)") — \(a.name ?? "(sin nombre)")")
                                .font(.body)
                            Text("parent=nil")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
    }
}
