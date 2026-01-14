//
//  BootstrapService.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-11.
//

import CoreData

enum BootstrapService {

    struct Result {
        let owner: AccountOwner
        let ledger: Ledger
        let currency: Commodity
    }

    /// Crea el primer libro contable del usuario.
    /// Lanza error si ya existe uno.
    static func createFirstLedger(
        context: NSManagedObjectContext,
        ownerDisplayName: String,
        ledgerName: String,
        currencyMnemonic: String
    ) throws -> Result {

        let ledgerCount = try context.count(for: Ledger.fetchRequest())
        guard ledgerCount == 0 else {
            throw NSError(
                domain: "Bootstrap",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Ya existe al menos un libro contable."]
            )
        }

        let now = Date()

        // 1) AccountOwner
        let owner = AccountOwner(context: context)
        owner.id = UUID()
        owner.displayName = ownerDisplayName
        owner.isActive = true
        owner.createdAt = now

        // 2) Currency (Commodity)
        let currency = Commodity(context: context)
        currency.id = UUID()
        currency.namespace = "CURRENCY"
        currency.mnemonic = currencyMnemonic
        currency.fullName = currencyMnemonic
        currency.fraction = 100
        currency.isActive = true
        currency.createdAt = now

        // 3) AccountTypes (SAT)
        let accountTypes = try createAccountTypes(context: context, now: now)

        // 4) Ledger
        let ledger = Ledger(context: context)
        ledger.id = UUID()
        ledger.name = ledgerName
        ledger.owner = owner
        ledger.isActive = true
        ledger.createdAt = now

        // 5) Root Account
        let root = Account(context: context)
        root.id = UUID()
        root.code = "ROOT"
        root.name = "Raíz"
        root.ledger = ledger
        root.parent = nil
        root.isPlaceholder = true
        root.createdAt = now
        root.isActive = true

        ledger.rootAccount = root

        try context.save()

        return Result(owner: owner, ledger: ledger, currency: currency)
    }

    // MARK: - Account Types

    private static func createAccountTypes(
        context: NSManagedObjectContext,
        now: Date
    ) throws -> [AccountType] {

        // Si ya existen, no los recreamos
        let req = AccountType.fetchRequest()
        if try context.count(for: req) > 0 {
            return []
        }

        // kind: Int16
        // 0 = Activo, 1 = Pasivo, 2 = Capital, 3 = Ingreso, 4 = Gasto
        let definitions: [(Int16, String, String)] = [
            (0, "ACTIVO", "Activo"),
            (1, "PASIVO", "Pasivo"),
            (2, "CAPITAL", "Capital"),
            (3, "INGRESO", "Ingreso"),
            (4, "GASTO", "Gasto")
        ]

        var created: [AccountType] = []

        for (kind, code, name) in definitions {
            let t = AccountType(context: context)
            t.id = UUID()
            t.kind = kind
            t.standard = "SAT"
            t.code = code
            t.name = name
            t.isActive = true
            t.createdAt = now
            created.append(t)
        }

        return created
    }
}
