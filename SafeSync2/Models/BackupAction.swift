//
//  BackuoAction.swift
//  SafeSync2
//
//  Created by Caio Gabriel de Moura Fortes on 07/04/26.
//

import Foundation

enum BackupAction: Sendable {
    case copyNew(source: URL, sourceRoot: URL, relativePath: String)
    case updateExisting(source: URL, sourceRoot: URL, relativePath: String)
    case skipUnchanged(relativePath: String)
}

struct BackupPlanResult: Sendable {
    var actions: [BackupAction]
    var skippedSymlinks: [URL]
    var errors: [String]
    
    var newFiles: [BackupAction] {
        actions.filter { if case .copyNew = $0 { return true } else { return false } }
    }
    
    var updatedFiles: [BackupAction] {
        actions.filter { if case .updateExisting = $0 { return true } else { return false } }
    }
    
    var unchangedCount: Int {
        actions.filter { if case .skipUnchanged = $0 { return true } else { return false } }.count
    }
    
    var hasWork: Bool {
        !newFiles.isEmpty || !updatedFiles.isEmpty
    }
}

struct BackupExecutionReport: Sendable {
    var copied: Int
    var updated: Int
    var failures: [String]
}

struct BackupPreviewData: Sendable {
    let planName: String
    let result: BackupPlanResult
    let sameVolume: Bool
    let totalSize: Int64?
    let availableSpace: Int64?
    
    var fitsInDestination: Bool {
        guard let totalSize, let availableSpace else { return true }
        return totalSize <= availableSpace
    }
    
    var isSpaceTight: Bool {
        guard let totalSize, let availableSpace, fitsInDestination else { return false }
        let remaining = availableSpace - totalSize
        let tenPercent = availableSpace / 10
        return remaining < tenPercent
    }
}
