//
//  CloudKitAccountChecker.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-08.
//

import CloudKit

final class CloudKitAccountChecker {
    static func checkAccountStatus() async -> Result<Void, String> {
        do {
            let status = try await CKContainer.default().accountStatus()
            switch status {
            case .available:
                return .success(())
            case .noAccount:
                return .failure("No hay una cuenta de iCloud iniciada en este Mac.")
            case .restricted:
                return .failure("El acceso a iCloud está restringido (MDM/controles).")
            case .couldNotDetermine:
                return .failure("No se pudo determinar el estado de iCloud.")
            @unknown default:
                return .failure("Estado de iCloud desconocido.")
            }
        } catch {
            return .failure("Error consultando iCloud: \(error.localizedDescription)")
        }
    }
}
