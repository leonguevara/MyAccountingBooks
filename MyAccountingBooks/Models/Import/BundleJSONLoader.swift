//
//  BundleJSONLoader.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-14.
//

import Foundation

enum BundleJSONLoader {
    static func loadData(named name: String) throws -> Data {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
            throw NSError(domain: "BundleJSONLoader", code: 1, userInfo: [NSLocalizedDescriptionKey: "No se encontró \(name).json en el bundle"])
        }
        return try Data(contentsOf: url)
    }
}
