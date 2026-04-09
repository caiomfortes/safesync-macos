//
//  SafeSync2App.swift
//  SafeSync2
//
//  Created by Caio Gabriel de Moura Fortes on 07/04/26.
//

import SwiftUI

@main
struct SafeSync2App: App {
    @State private var store = PlanStore()
    @State private var coordinator: BackupCoordinator
    
    init() {
        let store = PlanStore()
        self._store = State(initialValue: store)
        self._coordinator = State(initialValue: BackupCoordinator(store: store))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(store: store, coordinator: coordinator)
        }
    }
}
