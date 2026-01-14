//
//  ChartOfAccountsImporter.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-13.
//

import Foundation
import CoreData

enum ChartOfAccountsImporter {

    /// Tu código root artificial (nivel 0)
    static let rootCode = "000-000000000-000000"

    static func importCOAJSON(
        _ data: Data,
        into ledger: Ledger,
        context: NSManagedObjectContext
    ) throws {

        let items = try JSONDecoder().decode([COAAccountDTO].self, from: data)

        try context.performAndWait {

            func norm(_ s: String) -> String { s.trimmingCharacters(in: .whitespacesAndNewlines) }

            // 1) Trae cuentas existentes del ledger (para re-import sin duplicar)
            let req = Account.fetchRequest()
            req.predicate = NSPredicate(format: "ledger == %@", ledger)
            req.fetchBatchSize = 500
            let existing = (try? context.fetch(req)) ?? []

            var byCode: [String: Account] = [:]
            byCode.reserveCapacity(items.count + existing.count)

            for a in existing {
                if let c = a.code { byCode[norm(c)] = a }
            }

            // 2) PASADA 1: crea/actualiza todas las cuentas (sin parent todavía)
            for dto in items {
                let code = norm(dto.code)
                guard !code.isEmpty else { continue }

                let acc = byCode[code] ?? Account(context: context)
                acc.ledger = ledger
                acc.code = code
                acc.name = norm(dto.name)

                // Si tu modelo tiene "level" como atributo, asígnalo; si no, omite
                // acc.level = Int16(dto.level)

                /*if let k = dto.kind {
                    // si tu modelo usa `kind` (Int16) en Account para rol
                    acc.kind = k
                }*/

                if let notes = dto.notes {
                    acc.notes = notes
                }

                byCode[code] = acc
            }

            // 3) PASADA 2: enlaza parents
            for dto in items {
                let code = norm(dto.code)
                guard let acc = byCode[code] else { continue }

                if let p = dto.parentCode.map(norm), !p.isEmpty, let parent = byCode[p] {
                    acc.parent = parent
                } else {
                    acc.parent = nil
                }
            }

            // 4) Root del ledger: SIEMPRE tu raíz artificial
            if let root = byCode[rootCode] {
                ledger.rootAccount = root
            } else {
                // Si por alguna razón no venía root en el JSON, lo creamos
                let root = Account(context: context)
                root.ledger = ledger
                root.code = rootCode
                root.name = "Raíz"
                root.parent = nil
                byCode[rootCode] = root
                ledger.rootAccount = root
            }

            // 5) (Opcional pero recomendado) Validación rápida
            let total = byCode.values.filter { $0.ledger == ledger }.count
            let rootChildren = (ledger.rootAccount?.children as? Set<Account>)?.count ?? 0
            let orphans = byCode.values.filter { $0.ledger == ledger && $0.parent == nil && $0.code != rootCode }.count

            print("✅ COA import: total=\(total) rootChildren=\(rootChildren) orphans=\(orphans) root=\(ledger.rootAccount?.code ?? "nil")")

            try context.save()
        }
    }
}
