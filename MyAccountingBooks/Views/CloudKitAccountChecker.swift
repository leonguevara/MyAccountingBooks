//
//  CloudKitAccountChecker.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-08.
//

import CloudKit

final class CloudKitAccountChecker {

    static func checkAccountStatus() async -> Result<Void, CloudKitAccountError> {
        do {
            let status = try await CKContainer.default().accountStatus()

            switch status {
            case .available:
                return .success(())

            case .noAccount:
                return .failure(.noAccount)

            case .restricted:
                return .failure(.restricted)

            case .temporarilyUnavailable:
                return .failure(.temporarilyUnavailable)

            case .couldNotDetermine:
                return .failure(.couldNotDetermine)

            @unknown default:
                return .failure(.unknown)
            }
        } catch {
            return .failure(.underlying(error))
        }
    }
}
