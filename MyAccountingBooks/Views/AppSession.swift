//
//  AppSession.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-08.
//

import Foundation
import Combine

@MainActor
final class AppSession: ObservableObject {
    @Published var activeOwnerID: UUID?
    @Published var activeLedgerID: UUID?

    func setActive(ownerID: UUID?, ledgerID: UUID?) {
        activeOwnerID = ownerID
        activeLedgerID = ledgerID
    }

    func clear() {
        activeOwnerID = nil
        activeLedgerID = nil
    }
}
