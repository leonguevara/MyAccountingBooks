//
//  CloudKitAccountError.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-08.
//

import Foundation

enum CloudKitAccountError: LocalizedError {
    case noAccount
    case restricted
    case temporarilyUnavailable
    case couldNotDetermine
    case unknown
    case underlying(Error)

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
