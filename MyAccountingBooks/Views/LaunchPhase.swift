//
//  LaunchPhase.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-08.
//

import Foundation

enum LaunchPhase: Equatable {
    case checkingICloud
    case iCloudUnavailable(message: String)
    case loadingStore
    case syncing
    case ready(hasData: Bool)
}
