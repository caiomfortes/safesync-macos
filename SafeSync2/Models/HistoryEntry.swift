//
//  HistoryEntry.swift
//  SafeSync2
//
//  Created by Caio Gabriel de Moura Fortes on 09/04/26.
//


import Foundation

struct HistoryEntry: Identifiable, Codable, Sendable {
    let id: UUID
    let planID: UUID
    let planName: String
    let startedAt: Date
    let finishedAt: Date
    let wasMirrorMode: Bool
    let outcome: Outcome
    let copiedCount: Int
    let updatedCount: Int
    let orphansRemovedCount: Int
    let failureCount: Int
    let firstFailureMessage: String?
    
    enum Outcome: String, Codable, Sendable {
        case completed
        case failed
        case cancelled
    }
    
    var duration: TimeInterval {
        finishedAt.timeIntervalSince(startedAt)
    }
    
    init(
        planID: UUID,
        planName: String,
        startedAt: Date,
        finishedAt: Date = Date(),
        wasMirrorMode: Bool,
        outcome: Outcome,
        copiedCount: Int = 0,
        updatedCount: Int = 0,
        orphansRemovedCount: Int = 0,
        failureCount: Int = 0,
        firstFailureMessage: String? = nil
    ) {
        self.id = UUID()
        self.planID = planID
        self.planName = planName
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.wasMirrorMode = wasMirrorMode
        self.outcome = outcome
        self.copiedCount = copiedCount
        self.updatedCount = updatedCount
        self.orphansRemovedCount = orphansRemovedCount
        self.failureCount = failureCount
        self.firstFailureMessage = firstFailureMessage
    }
}