//
//  BundleJSONLoader.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-14.
//

import Foundation

/// A tiny utility for loading JSON files bundled with the app.
///
/// Use `BundleJSONLoader` to synchronously read the raw `Data` for a
/// JSON resource included in the app target. This is handy for fixtures,
/// bootstrap data, or offline resources that ship with the app.
///
/// The loader looks up files by name in `Bundle.main` with a `.json`
/// extension and throws if the resource can't be found or read.
enum BundleJSONLoader {
    /// Loads the raw bytes of a JSON file from the main bundle.
    ///
    /// - Parameter name: The resource name without the `.json` extension.
    /// - Returns: The file contents as `Data`.
    /// - Throws: An `NSError` if the resource is missing from the bundle or if
    ///   reading the file fails.
    ///
    /// Example:
    /// ```swift
    /// let data = try BundleJSONLoader.loadData(named: "SeedUsers")
    /// let users = try JSONDecoder().decode([User].self, from: data)
    /// ```
    static func loadData(named name: String) throws -> Data {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
            throw NSError(
                domain: "BundleJSONLoader",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "No se encontró \(name).json en el bundle (Target Membership)."]
            )
        }
        return try Data(contentsOf: url)
    }
}
