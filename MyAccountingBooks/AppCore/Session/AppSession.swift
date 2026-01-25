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
import CoreData

/// A main-actor observable session container for UI state.
///
/// Publishes identifiers for the active owner and ledger so views can react to selection changes.
@MainActor
final class AppSession: ObservableObject {
    /// The identifier of the currently active owner, if any.
    @Published var activeOwnerID: UUID? {
        didSet { persist() }
    }
    /// The identifier of the currently active ledger, if any.
    @Published var activeLedgerID: UUID? {
        didSet { persist() }
    }
    
    private enum Keys {
        static let activeOwnerID = "AppSession.activeOwnerID"
        static let activeLedgerID = "AppSession.activeLedgerID"
    }
    
    init() {
        // Restore persisted IDs (if any)
        if let s = UserDefaults.standard.string(forKey: Keys.activeOwnerID),
           let id = UUID(uuidString: s) {
            self.activeOwnerID = id
        }

        if let s = UserDefaults.standard.string(forKey: Keys.activeLedgerID),
           let id = UUID(uuidString: s) {
            self.activeLedgerID = id
        }
    }
    
    private func persist() {
        if let id = activeOwnerID {
            UserDefaults.standard.set(id.uuidString, forKey: Keys.activeOwnerID)
        } else {
            UserDefaults.standard.removeObject(forKey: Keys.activeOwnerID)
        }

        if let id = activeLedgerID {
            UserDefaults.standard.set(id.uuidString, forKey: Keys.activeLedgerID)
        } else {
            UserDefaults.standard.removeObject(forKey: Keys.activeLedgerID)
        }
    }

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
    
    /// Explicitly closes the current ledger (keeps owner if you want).
    func closeLedger() {
        activeLedgerID = nil
    }
    
    /// Marks a ledger as opened (and optionally sets owner).
    func openLedger(_ ledger: Ledger) {
        activeLedgerID = ledger.id
        // If your Ledger has an owner relationship, you can also set activeOwnerID here.
        if let owner = ledger.owner {
            activeOwnerID = owner.id
        }
    }
    
    /// Marks a ledger as opened (and optionally sets owner).
    func openLedger(id: UUID) {
        activeLedgerID = id
    }
    
    /// Devuelve el ledger activo si hay uno en sesión; si no, regresa nil.
    func resolveActiveLedger(in context: NSManagedObjectContext) -> Ledger? {
        guard let id = activeLedgerID else { return nil }

        let req: NSFetchRequest<Ledger> = Ledger.fetchRequest()
        req.fetchLimit = 1
        req.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        do {
            return try context.fetch(req).first
        } catch {
            return nil
        }
    }
}

