//
//  AppSession.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-08.
//

/// AppSession
///
/// Holds in-memory session state for the currently active owner and ledger.

import Foundation
import Combine

/// A main-actor observable session container for UI state.
///
/// Publishes identifiers for the active owner and ledger so views can react to selection changes.
@MainActor
final class AppSession: ObservableObject {
    /// The identifier of the currently active owner, if any.
    @Published var activeOwnerID: UUID?
    /// The identifier of the currently active ledger, if any.
    @Published var activeLedgerID: UUID?

    /// Sets the active owner and ledger identifiers.
    ///
    /// - Parameters:
    ///   - ownerID: The new active owner identifier, or `nil` to clear.
    ///   - ledgerID: The new active ledger identifier, or `nil` to clear.
    func setActive(ownerID: UUID?, ledgerID: UUID?) {
        activeOwnerID = ownerID
        activeLedgerID = ledgerID
    }

    /// Clears the active session identifiers.
    func clear() {
        activeOwnerID = nil
        activeLedgerID = nil
    }
}

