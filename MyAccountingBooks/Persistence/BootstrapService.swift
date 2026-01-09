//
//  BootstrapService.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-09.
//

import CoreData

enum BootstrapService {

    static func runIfNeeded(context: NSManagedObjectContext) throws {

            // OJO: count(for:) debe ejecutarse en la cola del contexto
            var ledgerCount = 0
            try context.performAndWait {
                ledgerCount = try context.count(for: Ledger.fetchRequest())
            }
            guard ledgerCount == 0 else { return }

            try context.performAndWait {
                let owner = Self.createDefaultOwner(context)
                let currency = Self.createDefaultCurrency(context)
                let accountTypes = Self.createAccountTypes(context)

                let ledger = Self.createLedger(context, owner: owner, currency: currency)
                let rootAccount = Self.createRootAccount(
                    context: context,
                    ledger: ledger,
                    currency: currency,
                    accountTypes: accountTypes
                )

                ledger.rootAccount = rootAccount
                try context.save()
            }
        }
    
    private static func createDefaultOwner(_ ctx: NSManagedObjectContext) -> AccountOwner {
        let owner = AccountOwner(context: ctx)
        owner.displayName = "Usuario principal"
        owner.isActive = true
        return owner
    }
    
    private static func createDefaultCurrency(_ ctx: NSManagedObjectContext) -> Commodity {
        let mxn = Commodity(context: ctx)
        mxn.namespace = "CURRENCY"
        mxn.mnemonic = "MXN"
        mxn.fullName = "Peso Mexicano"
        mxn.fraction = 100
        return mxn
    }

    private static func createAccountTypes(
        _ ctx: NSManagedObjectContext
    ) -> [AccountTypeKind: AccountType] {

        var result: [AccountTypeKind: AccountType] = [:]

        for kind in AccountTypeKind.allCases {
            let type = AccountType(context: ctx)
            type.kind = kind.rawValue
            type.standard = "SAT"
            type.code = kindCode(kind)
            type.name = kindName(kind)
            result[kind] = type
        }
        return result
    }

    private static func kindCode(_ kind: AccountTypeKind) -> String {
        switch kind {
        case .asset: return "ACT"
        case .liability: return "PAS"
        case .equity: return "CAP"
        case .income: return "ING"
        case .expense: return "GAS"
        }
    }

    private static func kindName(_ kind: AccountTypeKind) -> String {
        switch kind {
        case .asset: return "Activo"
        case .liability: return "Pasivo"
        case .equity: return "Capital"
        case .income: return "Ingreso"
        case .expense: return "Gasto"
        }
    }

    private static func createLedger(
        _ ctx: NSManagedObjectContext,
        owner: AccountOwner,
        currency: Commodity
    ) -> Ledger {
        let ledger = Ledger(context: ctx)
        ledger.name = "Libro principal"
        ledger.owner = owner
        ledger.currencyCode = currency.mnemonic
        ledger.isActive = true
        return ledger
    }

    private static func createChartOfAccounts(
        context ctx: NSManagedObjectContext,
        ledger: Ledger,
        currency: Commodity,
        accountTypes: [AccountTypeKind: AccountType]
    ) -> Account {

        let root = createAccount(
            ctx, name: "Root",
            ledger: ledger,
            currency: currency,
            type: nil,
            parent: nil,
            placeholder: true
        )

        createCategory("Activos", .asset)
        createCategory("Pasivos", .liability)
        createCategory("Capital", .equity)
        createCategory("Ingresos", .income)
        createCategory("Gastos", .expense)

        return root

        // MARK: - helpers

        func createCategory(_ name: String, _ kind: AccountTypeKind) {
            _ = createAccount(
                ctx,
                name: name,
                ledger: ledger,
                currency: currency,
                type: accountTypes[kind],
                parent: root,
                placeholder: true
            )
        }
    }

    private static func createAccount(
        _ ctx: NSManagedObjectContext,
        name: String,
        ledger: Ledger,
        currency: Commodity,
        type: AccountType?,
        parent: Account?,
        placeholder: Bool
    ) -> Account {

        let account = Account(context: ctx)
        account.name = name
        account.ledger = ledger
        account.commodity = currency
        account.accountType = type
        account.parent = parent
        account.isPlaceholder = placeholder
        account.isActive = true
        return account
    }

    private func createDefaultPayees(
        _ ctx: NSManagedObjectContext,
        ledger: Ledger
    ) {
        let opening = Payee(context: ctx)
        opening.name = "Saldo inicial"
        opening.ledger = ledger
        opening.isActive = true
    }

    private static func createRootAccount(
            context: NSManagedObjectContext,
            ledger: Ledger,
            currency: Commodity,
            accountTypes: [AccountTypeKind: AccountType]
        ) -> Account {
            let root = Account(context: context)
            root.name = "Root"
            root.ledger = ledger
            root.commodity = currency
            root.isPlaceholder = true
            root.accountType = accountTypes[.asset] // ejemplo
            return root
        }
}
