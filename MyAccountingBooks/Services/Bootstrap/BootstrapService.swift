//
//  BootstrapService.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-11.
//

/// BootstrapService
///
/// Creates initial Core Data records for a first-run experience: an `AccountOwner`, a `Ledger`,
/// a currency `Commodity`, a root `Account`, and standard `AccountType`s. Intended to run once
/// for a fresh profile.
//

import CoreData

/// Utilities to initialize baseline data for a new user/profile.
enum BootstrapService {

    /// The entities created by a successful bootstrap.
    struct Result {
        /// The created account owner entity.
        let owner: AccountOwner
        /// The created ledger associated with the owner.
        let ledger: Ledger
        /// The default currency commodity for the ledger.
        let currency: Commodity
    }

    /// Creates the initial ledger and related entities for a first-run experience.
    ///
    /// Performs the following steps atomically on the provided context:
    /// 1. Ensure no existing `Ledger` records are present.
    /// 2. Create an `AccountOwner` with the supplied display name.
    /// 3. Create a currency `Commodity` (namespace = "CURRENCY").
    /// 4. Seed standard `AccountType`s (SAT mapping) when none exist.
    /// 5. Create a `Ledger` associated to the owner.
    /// 6. Create a root `Account` for the ledger and link it as `rootAccount`.
    /// 7. Save the context.
    ///
    /// - Parameters:
    ///   - context: The Core Data context in which to create all entities.
    ///   - ownerDisplayName: The display name for the new owner.
    ///   - ledgerName: The display name for the new ledger.
    ///   - currencyMnemonic: The currency code/symbol (e.g., "MXN", "USD").
    /// - Returns: A `Result` containing references to the created owner, ledger, and currency.
    /// - Throws: An error if a ledger already exists or if the context save fails.
    static func createFirstLedger(
        context: NSManagedObjectContext,
        ownerDisplayName: String,
        ledgerName: String,
        currencyMnemonic: String
    ) throws -> Result {

        // Guard against running bootstrap more than once.
        let ledgerCount = try context.count(for: Ledger.fetchRequest())
        guard ledgerCount == 0 else {
            throw NSError(
                domain: "Bootstrap",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Ya existe al menos un libro contable."]
            )
        }

        // Capture a single timestamp for all created entities.
        let now = Date()

        // 1) AccountOwner
        // Create account owner.
        let owner = AccountOwner(context: context)
        owner.id = UUID()
        owner.displayName = ownerDisplayName
        owner.isActive = true
        owner.createdAt = now

        // 2) Currency (Commodity)
        // Create default currency commodity.
        let currency = Commodity(context: context)
        currency.id = UUID()
        currency.namespace = "CURRENCY"
        currency.mnemonic = currencyMnemonic
        currency.fullName = currencyMnemonic
        currency.fraction = 100
        currency.isActive = true
        currency.createdAt = now

        // 3) AccountTypes (SAT)
        // Seed standard account types if needed.
        let accountTypes = try createAccountTypes(context: context, now: now)

        // 4) Ledger
        // Create the ledger and associate it with the owner.
        let ledger = Ledger(context: context)
        ledger.id = UUID()
        ledger.name = ledgerName
        ledger.owner = owner
        ledger.isActive = true
        ledger.createdAt = now

        // 5) Root Account
        // Create and link the root account for the ledger.
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

    /// Creates standard account types when none exist.
    // MARK: - Account Types

    /// Seeds standard account types using SAT-like categories.
    ///
    /// - Parameters:
    ///   - context: The Core Data context used to insert entities.
    ///   - now: Timestamp applied to `createdAt`.
    /// - Returns: The array of created `AccountType`s, or an empty array when types already exist.
    private static func createAccountTypes(
        context: NSManagedObjectContext,
        now: Date
    ) throws -> [AccountType] {

        // Si ya existen, no los recreamos
        let req = AccountType.fetchRequest()
        if try context.count(for: req) > 0 {
            return []
        }

        // Mapping for kind values: 0=Activo, 1=Pasivo, 2=Capital, 3=Ingreso, 4=Gasto.
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
