//
//  ChartOfAccountsJSONImporter.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-10.
//

/// ChartOfAccountsJSONImporter
///
/// High-level: Imports a chart of accounts from a bundled JSON file into Core Data.
///
/// Responsibilities:
/// - Decode an array of account rows from a JSON resource in the main bundle.
/// - Create or update `Account` managed objects for a given `Ledger`.
/// - Infer placeholder accounts based on whether a node has children.
/// - Establish parent-child relationships, defaulting to the ledger's root when needed.
///
/// Input JSON fields per row:
/// - `code`: Unique account identifier (string).
/// - `parentCode`: Optional parent account code. Root rows omit this.
/// - `name`: Human-readable account name.
/// - `level`: Hierarchical depth (0 for root), used only as a hint.
/// - `kind`: Domain-specific kind mapped to `Account.kind`.
/// - `role`: Domain-specific role mapped to `Account.accountRole`.
///
/// Error handling:
/// - Throws `ChartImportError.resourceNotFound` if the resource cannot be located.
/// - Throws `ChartImportError.decodeFailed` if the JSON cannot be decoded or is empty.
//

import Foundation
import CoreData

/// Errors that can occur while importing the chart of accounts from JSON.
///
/// - resourceNotFound: The named JSON file was not found in the main bundle.
/// - decodeFailed: The JSON payload was found but could not be decoded into rows.
enum ChartImportError: LocalizedError {
    case resourceNotFound(String)
    case decodeFailed

    /// Localized, user-facing error description in Spanish.
    var errorDescription: String? {
        switch self {
        case .resourceNotFound(let name): return "No se encontró el recurso \(name).json en el bundle."
        case .decodeFailed: return "No fue posible decodificar el JSON del catálogo de cuentas."
        }
    }
}

/// A single row in the chart-of-accounts JSON.
///
/// This is a lightweight DTO used only for decoding. Its fields mirror the JSON schema
/// and are later mapped to the persistent `Account` entity.
struct ChartAccountRow: Decodable {
    /// Unique code of the account (serves as the primary key during import).
    let code: String
    /// Optional code of the parent account. Omit or null for root.
    let parentCode: String?
    /// Display name of the account.
    let name: String
    /// Hierarchical level (0 for root). Used as a hint; hierarchy is derived from `parentCode`.
    let level: Int
    /// Domain-specific kind mapped to `Account.kind`.
    let kind: Int16
    /// Domain-specific role mapped to `Account.accountRole`.
    let role: Int16
}

/// Imports a chart of accounts from a bundled JSON resource into a `Ledger`.
///
/// The importer is idempotent with respect to account `code`s: if an `Account` with a given
/// code already exists in the provided `ledger`, it will be updated in place; otherwise it is created.
/// Parent/child relationships are established after all accounts are present.
///
/// Placeholder accounts are inferred as those that have at least one child row in the JSON.
enum ChartOfAccountsJSONImporter {

    /// Imports accounts from a JSON resource in the main bundle into the given ledger/context.
    ///
    /// The operation performs two passes:
    /// 1. Create or update all `Account` objects without setting parent links.
    /// 2. Establish parent-child relationships using `parentCode`, defaulting to the ledger's root.
    ///
    /// If the ledger's root account does not exist, a minimal root is created using either the
    /// root row from JSON (level = 0, no `parentCode`) or a fallback code.
    ///
    /// - Parameters:
    ///   - ledger: The target `Ledger` that owns the imported accounts.
    ///   - context: The `NSManagedObjectContext` used to create/fetch `Account`s.
    ///   - resourceName: The base name (without extension) of the JSON file in the main bundle.
    /// - Throws: `ChartImportError.resourceNotFound` if the resource can't be located, or
    ///           `ChartImportError.decodeFailed` if the JSON can't be decoded or yields no rows.
    static func importFromBundledJSON(
        into ledger: Ledger,
        context: NSManagedObjectContext,
        resourceName: String
    ) throws {

        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "json") else {
            throw ChartImportError.resourceNotFound(resourceName)
        }

        let data = try Data(contentsOf: url)

        /// Decode the JSON payload into transient rows; treat failure as empty and validate below.
        let rows = (try? JSONDecoder().decode([ChartAccountRow].self, from: data)) ?? []
        guard !rows.isEmpty else { throw ChartImportError.decodeFailed }

        /// Build an index of children per parent code to quickly determine placeholder status.
        var childrenByParent: [String: [ChartAccountRow]] = [:]
        for r in rows {
            if let p = r.parentCode {
                childrenByParent[p, default: []].append(r)
            }
        }

        /// 2) Existing Root (if it was already created by BootstrapService)
        let currency = ledger.currencyCommodity
        let defaultSCU = Int32(currency?.fraction ?? 100)

        /// Fetch any existing accounts for this ledger so we can update in place (idempotent import).
        /// Map por code -> Account
        var accountsByCode: [String: Account] = [:]

        let fr = NSFetchRequest<Account>(entityName: "Account")
        fr.predicate = NSPredicate(format: "ledger == %@", ledger)
        if let existing = try? context.fetch(fr) {
            for a in existing {
                if let c = a.code {
                    accountsByCode[c] = a
                }
            }
        }

        /// 3) Set rootCode (if it comes in the JSON file with level=0)
        /// Prefer a JSON-declared root by code, otherwise reuse the ledger's existing root, else create one.
        let jsonRoot = rows.first(where: { $0.level == 0 && $0.parentCode == nil })
        let rootAccount: Account
        if let jsonRoot, let existingRoot = accountsByCode[jsonRoot.code] {
            rootAccount = existingRoot
        } else if let existingRoot = ledger.rootAccount {
            rootAccount = existingRoot
        } else {
            /// fallback: create minimum root in case it does not exist
            let root = Account(context: context)
            root.createdAt = Date()
            root.id = UUID()
            root.isActive = true
            root.isHidden = false
            root.isPlaceholder = true
            root.kind = 1
            root.accountRole = 0
            root.name = "Raíz"
            root.code = jsonRoot?.code ?? "000-000000000-000000"
            root.ledger = ledger
            root.rootOfLedger = ledger
            root.commodity = currency
            root.commoditySCU = defaultSCU
            rootAccount = root
            ledger.rootAccount = root
            accountsByCode[root.code ?? ""] = root
        }

        /// 4) First pass: materialize/update all accounts and basic attributes without linking parents.
        for r in rows {
            /// root is already covered
            if r.level == 0 && r.parentCode == nil { continue }

            let acc = accountsByCode[r.code] ?? Account(context: context)

            if acc.createdAt == nil { acc.createdAt = Date() }
            if acc.id == nil { acc.id = UUID() }

            acc.isActive = true
            acc.isHidden = false
            acc.code = r.code
            acc.name = r.name
            acc.kind = r.kind
            acc.accountRole = r.role

            /// placeholder = "has children"
            let hasChildren = (childrenByParent[r.code]?.isEmpty == false)
            acc.isPlaceholder = hasChildren

            /// ledger + commodity defaults
            acc.ledger = ledger
            acc.commodity = currency
            acc.commoditySCU = defaultSCU

            accountsByCode[r.code] = acc
        }

        /// 5) Second pass: resolve and assign parent relationships.
        for r in rows {
            guard let acc = accountsByCode[r.code] else { continue }

            if r.level == 0 && r.parentCode == nil {
                acc.parent = nil
                continue
            }

            if let parentCode = r.parentCode, let parent = accountsByCode[parentCode] {
                acc.parent = parent
            } else {
                /// if it has no parentCode, then it is attached to root
                acc.parent = rootAccount
            }
        }

        /// Ensure the ledger <-> root bidirectional link is consistent.
        rootAccount.rootOfLedger = ledger
        ledger.rootAccount = rootAccount
    }
}

