//
//  BackupProgress.swift
//  SafeSync2
//
//  Created by Caio Gabriel de Moura Fortes on 08/04/26.
//


import Foundation

struct BackupProgress: Sendable {
    enum Phase: Sendable {
        case queued
        case analyzing
        case waitingConfirmation
        case copying
        case finishing
        case completed
        case failed(String)
        case cancelled
    }
    
    var phase: Phase
    var filesProcessed: Int
    var filesTotal: Int
    var bytesProcessed: Int64
    var bytesTotal: Int64
    var startedAt: Date
    
    var fileFraction: Double {
        guard filesTotal > 0 else { return 0 }
        return Double(filesProcessed) / Double(filesTotal)
    }
    
    var byteFraction: Double {
        guard bytesTotal > 0 else { return 0 }
        return Double(bytesProcessed) / Double(bytesTotal)
    }
    
    var elapsedSeconds: TimeInterval {
        Date().timeIntervalSince(startedAt)
    }
    
    var estimatedSecondsRemaining: TimeInterval? {
        guard bytesTotal > 0, bytesProcessed > 0 else { return nil }
        let bytesPerSecond = Double(bytesProcessed) / elapsedSeconds
        guard bytesPerSecond > 0 else { return nil }
        let bytesRemaining = Double(bytesTotal - bytesProcessed)
        return bytesRemaining / bytesPerSecond
    }
}
