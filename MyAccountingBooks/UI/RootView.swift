//
//  RootView.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-08.
//

import SwiftUI
import CoreData

struct RootView: View {
    @Environment(\.managedObjectContext) private var moc
    private let persistence = PersistenceController.shared

    @StateObject private var launch = AppLaunchController()
    //@StateObject private var session = AppSession()

    @State private var showOnboarding = false

    var body: some View {
        content
            .onAppear {
                launch.start(using: persistence)
            }
    }

    @ViewBuilder
    private var content: some View {
        switch launch.phase {
        case .checkingICloud, .loadingStore, .syncing, .iCloudUnavailable:
            WelcomeGateView(launch: launch)

        case .ready(let hasData):
            AppShellView()
                //.environmentObject(session)
                .onAppear { showOnboarding = !hasData }
                .sheet(isPresented: $showOnboarding, onDismiss: refreshHasData) {
                    OnboardingWizardView(
                        onCancel: {
                            showOnboarding = false
                        },
                        onFinished: {
                            showOnboarding = false
                            refreshHasData()
                        }
                    )
                    .environment(\.managedObjectContext, moc)
                    //.environmentObject(session)
                }
        }
    }

    private func refreshHasData() {
        let count = (try? moc.count(for: Ledger.fetchRequest())) ?? 0
        showOnboarding = (count == 0)
    }
}

