//
//  CloudKitAccountChecker.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-08.
//

/// CloudKitAccountChecker
///
/// Utilities to verify the user's iCloud account status for CloudKit-backed features.
//

import CloudKit

/// Checks CloudKit account availability and maps statuses to app-specific errors.
final class CloudKitAccountChecker {

    /// Asynchronously queries `CKContainer.default()` for the current account status.
    ///
    /// - Returns: `.success(())` when the account is available; otherwise `.failure` with a
    ///   `CloudKitAccountError` describing the condition (no account, restricted, temporarily
    ///   unavailable, could not determine, unknown, or underlying error).
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

