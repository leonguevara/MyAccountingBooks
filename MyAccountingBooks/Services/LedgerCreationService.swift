//
//  LedgerCreationService.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-10.
//

import Foundation
import CoreData

@MainActor
enum LedgerCreationService {

    static func createFirstLedgerFromExcelTemplate(
        context: NSManagedObjectContext,
        ownerName: String,
        ledgerName: String,
        standard: String
    ) async throws {

        try context.performAndWait {

            // Owner
            let owner = AccountOwner(context: context)
            owner.id = UUID()
            owner.displayName = ownerName
            owner.isActive = true

            // Ledger
            let ledger = Ledger(context: context)
            ledger.id = UUID()
            ledger.name = ledgerName
            ledger.owner = owner

            // Root Account
            let root = Account(context: context)
            root.id = UUID()
            root.code = "ROOT"
            root.name = "Cuentas"
            root.ledger = ledger
            root.parent = nil

            ledger.rootAccount = root

            try context.save()

            // Importa catálogo
            try ChartOfAccountsJSONImporter.importFromBundledJSON(
                into: ledger,
                context: context,
                resourceName: "chart_of_accounts"
            )

        }
    }
}
