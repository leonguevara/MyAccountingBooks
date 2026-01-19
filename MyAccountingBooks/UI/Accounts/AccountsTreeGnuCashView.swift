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

    @StateObject private var balanceService = AccountBalanceService()

    private var root: Account? { ledger.rootAccount }

    var body: some View {
        VStack(alignment: .leading) {

            if let err = balanceService.lastErrorMessage {
                Text(err).foregroundStyle(.red)
            }

            if let root {
                List {
                    OutlineGroup([root], children: \.childrenArrayOptional) { account in
                        HStack(spacing: 12) {
                            Text(account.name ?? "(sin nombre)")
                                .frame(width: 280, alignment: .leading)

                            Text(roleLabel(account.accountRole))
                                .foregroundStyle(.secondary)
                                .frame(width: 180, alignment: .leading)

                            Text(balanceText(for: account))
                                .monospacedDigit()
                                .frame(width: 160, alignment: .trailing)
                        }
                    }
                }
            } else {
                ContentUnavailableView("No hay rootAccount",
                                      systemImage: "exclamationmark.triangle")
            }
        }
        .onAppear {
            balanceService.recompute(in: ledger, context: moc)
        }
        .toolbar {
            Button("Recalcular balances") {
                balanceService.recompute(in: ledger, context: moc)
            }
        }
    }

    private func balanceText(for account: Account) -> String {
        let raw = AccountBalanceService.totalBalance(
            for: account,
            balances: balanceService.lastBalances
        )

        let shown = AccountBalanceService.displayBalanceGnuCashStyle(
            kind: account.kind,
            rawBalance: raw
        )

        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.currencyCode = ledger.currencyCode
        nf.maximumFractionDigits = Int(ledger.precision)
        nf.minimumFractionDigits = Int(ledger.precision)

        return nf.string(from: shown as NSDecimalNumber) ?? "\(shown)"
    }

    private func roleLabel(_ raw: Int16) -> String {
        // ajusta a tu enum AccountRole
        // ejemplo:
        return AccountRole(rawValue: raw)?.label ?? "-"
    }
}
