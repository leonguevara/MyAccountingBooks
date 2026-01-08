//
//  MyAccountingBooksApp.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-06.
//

import SwiftUI
import CoreData

@main
struct MyAccountingBooksApp: App {
    /*let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }*/
    @StateObject private var persistence = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.managedObjectContext, persistence.container.viewContext)
                .environmentObject(persistence)
        }
    }
}
