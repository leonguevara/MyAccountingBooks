//
//  WelcomeGateView.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-08.
//

import SwiftUI
import AppKit

struct WelcomeGateView: View {
    @ObservedObject var launch: AppLaunchController

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("MyAccountingBooks")
                .font(.largeTitle)

            switch launch.phase {
            case .checkingICloud:
                Text("Verificando iCloud…")
                ProgressView()

            case .loadingStore:
                Text("Cargando base de datos…")
                ProgressView()

            case .syncing:
                HStack {
                    Text(launch.isSyncing ? "Sincronizando con iCloud…" : "Preparando…")
                    Spacer()
                    ProgressView()
                }

            case .iCloudUnavailable(let message):
                Text("iCloud no disponible")
                    .font(.title2)
                Text(message)
                    .foregroundStyle(.secondary)

                HStack {
                    Button("Abrir System Settings") { openSystemSettings() }
                    Button("Reintentar") { launch.retry() }
                }

            case .ready:
                Text("Listo")
            }

            Spacer()
        }
        .padding(24)
        .frame(minWidth: 560, minHeight: 360)
    }

    private func openSystemSettings() {
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/System Settings.app"))
    }
}
