//
//  BackuoAction.swift
//  SafeSync2
//
//  Created by Caio Gabriel de Moura Fortes on 07/04/26.
//

import Foundation

enum BackupAction {
    case copyNew(source: URL, sourceRoot: URL, relativePath: String)
    case updateExisting(source: URL, sourceRoot: URL, relativePath: String)
    case skipUnchanged(relativePath: String)
}

struct BackupPlanResult {
    var actions: [BackupAction]
    var skippedSymlinks: [URL]
    var errors: [String]
}

struct BackupExecutionReport {
    var copied: Int
    var updated: Int
    var failures: [String]
}
