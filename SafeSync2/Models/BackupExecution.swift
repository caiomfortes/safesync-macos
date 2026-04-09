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
    let originatedFromPopover: Bool
    
    init(
        planID: UUID,
        planName: String,
        progress: BackupProgress,
        originatedFromPopover: Bool = false
    ) {
        self.id = UUID()
        self.planID = planID
        self.planName = planName
        self.progress = progress
        self.previewData = nil
        self.originatedFromPopover = originatedFromPopover
    }
}
