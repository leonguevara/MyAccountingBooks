//
//  AccountTypeKind.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-09.
//

enum AccountTypeKind: Int16, CaseIterable {
    case asset = 1
    case liability
    case equity
    case income
    case expense
}
