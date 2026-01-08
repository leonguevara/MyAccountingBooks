//
//  RootView.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-08.
//

import SwiftUI
import CoreData

struct RootView: View {
    @EnvironmentObject private var persistence: PersistenceController
    @StateObject private var launch = AppLaunchController()

    @State private var showOnboarding = false

    var body: some View {
        Group {
            switch launch.phase {
            case .checkingICloud, .loadingStore, .syncing, .iCloudUnavailable:
                WelcomeGateView(launch: launch)

            case .ready(let hasData):
                AppShellView()
                    .onAppear {
                        showOnboarding = !hasData
                    }
                    .sheet(isPresented: $showOnboarding, onDismiss: refreshHasData) {
                        OnboardingWizardView(onFinished: {
                            showOnboarding = false
                            refreshHasData()
                        })
                        .environment(\.managedObjectContext, persistence.viewContext)
                    }
            }
        }
        .onAppear {
            launch.start(using: persistence)
        }
    }

    private func refreshHasData() {
        let count = (try? persistence.viewContext.count(for: Ledger.fetchRequest())) ?? 0
        showOnboarding = (count == 0)
    }
}
