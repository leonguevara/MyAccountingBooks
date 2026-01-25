//
//  LedgerServices.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-24.
//
//  Crear / inactivar (solo lectura) / borrar / cerrar libro
//

import Foundation
import CoreData

enum LedgerServiceError: LocalizedError {
    case missingLedgerName
    case ledgerNotFound
    case cannotDeleteActiveLedger

    var errorDescription: String? {
        switch self {
        case .missingLedgerName:
            return "El nombre del libro no puede estar vacío."
        case .ledgerNotFound:
            return "No se encontró el libro."
        case .cannotDeleteActiveLedger:
            return "No puedes borrar el libro que está abierto. Ciérralo primero."
        }
    }
}

final class LedgerService {

    // MARK: - Create

    /// Crea un Ledger nuevo. (No lo abre automáticamente: eso lo decides en UI/AppSession.)
    @discardableResult
    static func createLedger(
        name: String,
        currencyCode: String,
        precision: Int16,
        context: NSManagedObjectContext
    ) throws -> Ledger {

        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw LedgerServiceError.missingLedgerName }

        let ledger = Ledger(context: context)
        ledger.id = ledger.id ?? UUID()
        ledger.name = trimmed
        ledger.currencyCode = currencyCode
        ledger.precision = precision
        ledger.isActive = true
        ledger.createdAt = ledger.createdAt ?? Date()

        // Si tu modelo tiene relación rootAccount, normalmente se setea en tu bootstrap/import.
        // Aquí NO la creamos para no duplicar lógica.

        try context.save()
        return ledger
    }

    // MARK: - Read helpers

    static func fetchLedger(by id: UUID, context: NSManagedObjectContext) throws -> Ledger {
        let req = Ledger.fetchRequest()
        req.fetchLimit = 1
        req.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        let out = try context.fetch(req)
        guard let ledger = out.first else { throw LedgerServiceError.ledgerNotFound }
        return ledger
    }

    // MARK: - Archive / Inactivate

    static func setArchived(
        _ ledger: Ledger,
        archived: Bool,
        context: NSManagedObjectContext
    ) throws {
        ledger.isActive = !archived
        try context.save()
    }

    static func toggleArchived(_ ledger: Ledger, context: NSManagedObjectContext) throws {
        ledger.isActive.toggle()
        try context.save()
    }

    // MARK: - Close (session-level)

    /// “Cerrar libro” es una acción de sesión: la entidad no se modifica.
    /// La hacemos aquí para centralizar y porque tu UI la pide.
    static func closeActiveLedger(session: AppSession) {
        session.closeLedger()
    }

    // MARK: - Delete

    /// Borra un libro. Requiere que NO esté abierto.
    /// Nota: lo que se borra “en cascada” depende de tu modelo (Delete Rule).
    static func deleteLedger(
        _ ledger: Ledger,
        activeLedgerID: UUID?,
        context: NSManagedObjectContext
    ) throws {
        if let activeLedgerID, ledger.id == activeLedgerID {
            throw LedgerServiceError.cannotDeleteActiveLedger
        }
        context.delete(ledger)
        try context.save()
    }
}
