//
//  ChartOfAccountsJSONImporter.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-10.
//

import Foundation
import CoreData

/// A utility namespace that imports a Chart of Accounts (COA) from JSON into Core Data.
///
/// Overview
/// - Decodes an array of `COAAccountDTO` from JSON and mirrors it into `Account` entities
///   attached to a specific `Ledger`.
/// - Operates idempotently by indexing existing accounts by normalized `code` and then
///   creating or updating accounts to match the JSON payload.
/// - Establishes parent/child relationships in a second pass and guarantees a root account
///   on the `Ledger` using `rootCode` when missing.
///
/// Behavior
/// - Normalizes incoming string fields by trimming whitespace and newlines.
/// - For existing or newly created accounts, sets: `ledger`, `code`, `name`, `kind`,
///   `accountRole`, and `isPlaceholder` (if present in the DTO).
/// - Ensures `createdAt` is a valid, non-negative timestamp, defaulting to `Date()` when
///   absent or invalid.
/// - Links parents after all accounts are created to avoid order dependencies in the input.
/// - Assigns or creates the ledger's `rootAccount` using `rootCode`, marking it as a
///   placeholder.
///
/// Side Effects
/// - Persists changes by calling `context.save()` within a `performAndWait` block.
/// - Logs a concise import summary to help diagnose the resulting structure.
enum ChartOfAccountsJSONImporter {

    /// Canonical account code used to locate or create the ledger's root account.
    static let rootCode = "000-000000000-000000"

    /// Imports a chart of accounts from a JSON resource bundled with the app.
    ///
    /// - Parameters:
    ///   - ledger: The target `Ledger` that will own the imported accounts.
    ///   - context: The `NSManagedObjectContext` used for decoding and persistence.
    ///   - resourceName: The bundle resource name (without extension) that contains the JSON.
    /// - Throws: Any error from resource loading, JSON decoding, or Core Data save operations.
    /// - Note: This method loads the data using `BundleJSONLoader` and delegates to `importCOAJSON`.
    static func importFromBundledJSON(
        into ledger: Ledger,
        context: NSManagedObjectContext,
        resourceName: String
    ) throws {
        let data = try BundleJSONLoader.loadData(named: resourceName)
        try importCOAJSON(data, into: ledger, context: context)
    }

    /// Imports a chart of accounts from raw JSON data into the given ledger and context.
    ///
    /// This routine is designed to be idempotent with respect to (ledger, code). It will create
    /// accounts that do not exist and update those that do, based on the normalized `code` field
    /// of each DTO. Parent relationships are established in a second pass after all accounts are
    /// materialized.
    ///
    /// - Parameters:
    ///   - data: The JSON payload containing an array of `COAAccountDTO` entries.
    ///   - ledger: The `Ledger` that will own the accounts.
    ///   - context: The `NSManagedObjectContext` used for fetches, inserts, and saving.
    /// - Throws: Errors from JSON decoding or Core Data operations (including `save()`).
    /// - Important: Ensures a root account exists using `rootCode`. If not found in the payload,
    ///   a placeholder root is created and assigned to `ledger.rootAccount`.
    static func importCOAJSON(
        _ data: Data,
        into ledger: Ledger,
        context: NSManagedObjectContext
    ) throws {

        let items = try JSONDecoder().decode([COAAccountDTO].self, from: data)

        try context.performAndWait {
            func norm(_ s: String) -> String { s.trimmingCharacters(in: .whitespacesAndNewlines) }
            let now = Date()

            // 1) Index ledger+code (idempotencia)
            let req = Account.fetchRequest()
            req.predicate = NSPredicate(format: "ledger == %@", ledger)
            req.fetchBatchSize = 500
            let existing = (try? context.fetch(req)) ?? []

            var byCode: [String: Account] = [:]
            byCode.reserveCapacity(existing.count + items.count)
            for a in existing {
                if let c = a.code { byCode[norm(c)] = a }
            }

            // 2) 1st Pass: creates/updates all
            for dto in items {
                let code = norm(dto.code)
                guard !code.isEmpty else { continue }

                let acc = byCode[code] ?? Account(context: context)
                acc.ledger = ledger
                acc.code = code
                acc.name = norm(dto.name)

                // ✅ XML Model: Account.kind + Account.accountRole
                acc.kind = dto.kind
                acc.accountRole = dto.role

                if let ph = dto.isPlaceholder { acc.isPlaceholder = ph }

                // createdAt existes in XML; it defaults to 2001, pero we can set it if you want.
                let created = acc.createdAt
                if created == nil || (created?.timeIntervalSince1970 ?? 0) < 0 {
                    acc.createdAt = now
                }

                byCode[code] = acc
            }

            // 3) 2nd Pass: links to parent
            for dto in items {
                let code = norm(dto.code)
                guard let acc = byCode[code] else { continue }

                if let p = dto.parentCode.map(norm), !p.isEmpty, let parent = byCode[p] {
                    acc.parent = parent
                } else {
                    acc.parent = nil
                }
            }

            // 4) rootAccount: Ledger.rootAccount inverse rootOfLedger (according to XML)
            if let root = byCode[rootCode] {
                ledger.rootAccount = root
                root.isPlaceholder = true
            } else {
                // fallback: crear root
                let root = Account(context: context)
                root.ledger = ledger
                root.code = rootCode
                root.name = "Raíz"
                root.kind = AccountTypeKind.asset.rawValue
                root.accountRole = AccountRole.asset.rawValue
                root.isPlaceholder = true
                root.createdAt = now
                root.parent = nil
                ledger.rootAccount = root
                byCode[rootCode] = root
            }

            let total = byCode.values.filter { $0.ledger == ledger }.count
            let orphans = byCode.values.filter { $0.ledger == ledger && $0.parent == nil && $0.code != rootCode }.count
            let rootChildren = (ledger.rootAccount?.children as? Set<Account>)?.count ?? 0
            print("✅ COA import OK | total=\(total) rootChildren=\(rootChildren) orphans=\(orphans)")

            try context.save()
        }
    }
}
