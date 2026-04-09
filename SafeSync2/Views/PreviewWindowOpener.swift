//
//  PreviewWindowOpener.swift
//  SafeSync2
//
//  Created by Caio Gabriel de Moura Fortes on 09/04/26.
//


import SwiftUI

struct PreviewWindowOpener: View {
    let coordinator: BackupCoordinator
    
    @Environment(\.openWindow) private var openWindow
    @State private var alreadyOpenedFor: Set<UUID> = []
    
    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .onChange(of: pendingExecutionIDs) { _, newIDs in
                for id in newIDs where !alreadyOpenedFor.contains(id) {
                    alreadyOpenedFor.insert(id)
                    openWindow(id: "preview")
                }
                
                alreadyOpenedFor = alreadyOpenedFor.intersection(currentlyTrackableIDs)
            }
    }
    
    private var pendingExecutionIDs: Set<UUID> {
        Set(coordinator.executions.compactMap { execution -> UUID? in
            guard execution.originatedFromPopover else { return nil }
            if case .waitingConfirmation = execution.progress.phase {
                return execution.id
            }
            return nil
        })
    }
    
    private var currentlyTrackableIDs: Set<UUID> {
        Set(coordinator.executions.map { $0.id })
    }
}