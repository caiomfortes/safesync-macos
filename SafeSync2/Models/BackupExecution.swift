//
//  BackupExecution.swift
//  SafeSync2
//
//  Created by Caio Gabriel de Moura Fortes on 08/04/26.
//


import Foundation

struct BackupExecution: Identifiable, Sendable {
    let id: UUID
    let planID: UUID
    let planName: String
    var progress: BackupProgress
    var previewData: BackupPreviewData?
    
    init(
        planID: UUID,
        planName: String,
        progress: BackupProgress
    ) {
        self.id = UUID()
        self.planID = planID
        self.planName = planName
        self.progress = progress
        self.previewData = nil
    }
}