//
//  MyAccountingBooksApp.swift
//  MyAccountingBooks
//
//  Created by León Felipe Guevara Chávez on 2026-01-06.
//

/// MyAccountingBooksApp
///
/// The SwiftUI app entry point. Configures the Core Data environment and hosts the root view.
//

import SwiftUI
import CoreData

/// The main application type for MyAccountingBooks.
///
/// Initializes a shared `PersistenceController` and injects its `viewContext` into the SwiftUI
/// environment so that descendant views can access Core Data. The app presents `RootView` as the
/// main content inside a single `WindowGroup` scene.
@main
struct MyAccountingBooksApp: App {
    /// Shared Core Data stack used for the app's managed object context.
    private let persistence = PersistenceController.shared
    @StateObject private var session = AppSession()
    
    /// Declares the app's scenes and injects the managed object context into the environment.
    var body: some Scene {
        WindowGroup {
            // Root of the app's UI hierarchy.
            RootView()
                .environment(\.managedObjectContext, persistence.viewContext)
                .environmentObject(session)
                // .environmentObject(PersistenceController.shared)
        }
    }
}

