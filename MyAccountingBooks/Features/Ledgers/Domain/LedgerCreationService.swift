//
//  LedgerCreationService.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-10.
//

/// LedgerCreationService
///
/// Creates a first ledger and seeds its chart of accounts from a bundled JSON template.
//

import Foundation
import CoreData

/// Main-actor utilities for creating a starter ledger and importing its chart of accounts.
@MainActor
enum LedgerCreationService {

    /// Creates an owner, ledger, and root account, then imports a chart of accounts from the bundle.
    ///
    /// The operation runs on the context's queue using `performAndWait` to ensure consistency, then
    /// calls `ChartOfAccountsJSONImporter.importFromBundledJSON` to populate the ledger hierarchy.
    ///
    /// - Parameters:
    ///   - context: The Core Data context where entities are created and imported.
    ///   - ownerName: Display name for the new account owner.
    ///   - ledgerName: Display name for the new ledger.
    ///   - standard: Reserved for future template selection; currently unused.
    /// - Throws: Any error thrown by Core Data operations or the JSON importer.
    static func createFirstLedgerFromExcelTemplate(
        context: NSManagedObjectContext,
        ownerName: String,
        ledgerName: String,
        standard: String
    ) async throws {

        try context.performAndWait {

            // Create owner.
            let owner = AccountOwner(context: context)
            owner.id = UUID()
            owner.displayName = ownerName
            owner.isActive = true

            // Create ledger and associate to owner.
            let ledger = Ledger(context: context)
            ledger.id = UUID()
            ledger.name = ledgerName
            ledger.owner = owner

            // Create root account and link it to the ledger.
            let root = Account(context: context)
            root.id = UUID()
            root.code = "ROOT"
            root.name = "Cuentas"
            root.ledger = ledger
            root.parent = nil

            ledger.rootAccount = root

            // Persist initial entities before importing the chart.
            try context.save()

            // Import chart of accounts from bundled JSON (resource: "chart_of_accounts").
            try ChartOfAccountsJSONImporter.importFromBundledJSON(
                into: ledger,
                context: context,
                resourceName: "chart_of_accounts"
            )

        }
    }
}
