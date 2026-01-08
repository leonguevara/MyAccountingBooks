//
//  OnboardingWizardView.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-08.
//

import SwiftUI

struct OnboardingWizardView: View {
    var onFinished: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Configuración inicial")
                .font(.title2)

            Text("Aquí haremos preguntas para crear tu primer libro (Owner + Ledger + moneda + SAT/NIIF).")
                .foregroundStyle(.secondary)

            HStack {
                Button("Cancelar") { onFinished() }
                Button("Crear primer libro") {
                    // Aquí conectaremos bootstrap + import template
                    onFinished()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(minWidth: 640, minHeight: 420)
    }
}
