//
//  ChartOfAccountsJSONImporter.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-10.
//

import Foundation
import CoreData


enum ChartJSONImportError: Error, LocalizedError {
    case resourceNotFound(String)
    case decodeFailed
    case duplicateCode(String)
    case missingParent(code: String, parent: String)

    var errorDescription: String? {
        switch self {
        case .resourceNotFound(let name):
            return "No se encontró \(name) en el bundle."
        case .decodeFailed:
            return "No pude decodificar el JSON del catálogo."
        case .duplicateCode(let code):
            return "Código duplicado en JSON: \(code)"
        case .missingParent(let code, let parent):
            return "La cuenta \(code) referencia un padre inexistente: \(parent)"
        }
    }
}

struct ChartAccountDTO: Codable {
    let code: String
    let parentCode: String?
    let name: String
    let level: Int?
}

enum ChartOfAccountsJSONImporter {

    static func importFromBundledJSON(
        into ledger: Ledger,
        context: NSManagedObjectContext,
        resourceName: String = "chart_of_accounts"
    ) throws {

        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "json") else {
            throw ChartJSONImportError.resourceNotFound("\(resourceName).json")
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()

        guard let items = try? decoder.decode([ChartAccountDTO].self, from: data) else {
            throw ChartJSONImportError.decodeFailed
        }

        try context.performAndWait {
            var byCode: [String: Account] = [:]

            // 1) Crear todas las cuentas
            for item in items {
                if byCode[item.code] != nil {
                    throw ChartJSONImportError.duplicateCode(item.code)
                }

                let acc = Account(context: context)
                acc.id = UUID()
                acc.code = item.code
                acc.name = item.name
                acc.ledger = ledger
                byCode[item.code] = acc
            }

            // 2) Relacionar padre/hijo
            for item in items {
                guard let acc = byCode[item.code] else { continue }

                if let parentCode = item.parentCode, !parentCode.isEmpty {
                    guard let parentAcc = byCode[parentCode] else {
                        throw ChartJSONImportError.missingParent(code: item.code, parent: parentCode)
                    }
                    acc.parent = parentAcc
                } else {
                    acc.parent = ledger.rootAccount
                }
            }

            try context.save()
        }
    }
}
