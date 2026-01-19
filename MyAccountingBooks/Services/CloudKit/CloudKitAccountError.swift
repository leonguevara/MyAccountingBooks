//
//  CloudKitAccountError.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-08.
//

/// CloudKitAccountError
///
/// App-specific error type that represents CloudKit account availability issues and maps to
/// localized, user-facing messages.
//

import Foundation

/// Errors describing iCloud account states relevant to CloudKit usage.
enum CloudKitAccountError: LocalizedError {
    /// No iCloud account is signed in on the device.
    case noAccount
    /// iCloud access is restricted (e.g., MDM or parental controls).
    case restricted
    /// iCloud services are temporarily unavailable.
    case temporarilyUnavailable
    /// The account status could not be determined.
    case couldNotDetermine
    /// An unknown account status was returned.
    case unknown
    /// Wraps an underlying error returned by CloudKit APIs.
    case underlying(Error)

    /// Localized, user-facing description for each error case.
    var errorDescription: String? {
        switch self {
        case .noAccount:
            return "No hay una cuenta de iCloud iniciada en este Mac."
        case .restricted:
            return "El acceso a iCloud está restringido (MDM/controles)."
        case .temporarilyUnavailable:
            return "iCloud está temporalmente no disponible. Intenta más tarde."
        case .couldNotDetermine:
            return "No se pudo determinar el estado de iCloud."
        case .unknown:
            return "Estado de iCloud desconocido."
        case .underlying(let error):
            return "Error consultando iCloud: \(error.localizedDescription)"
        }
    }
}

