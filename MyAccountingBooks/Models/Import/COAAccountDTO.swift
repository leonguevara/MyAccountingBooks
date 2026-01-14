//
//  COAAccountDTO.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-13.
//

import Foundation

struct COAAccountDTO: Decodable {
    let code: String
    let parentCode: String?
    let name: String
    let level: Int

    // opcionales por si luego los agregas
    let kind: Int16?
    let notes: String?
}
