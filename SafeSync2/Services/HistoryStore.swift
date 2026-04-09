//
//  HistoryStore.swift
//  SafeSync2
//
//  Created by Caio Gabriel de Moura Fortes on 09/04/26.
//


import Foundation
import Observation

@Observable
@MainActor
final class HistoryStore {
    
    private(set) var entries: [HistoryEntry] = []
    
    private let fileManager = FileManager.default
    private let storeURL: URL
    private let maxEntriesPerPlan = 100
    
    init() {
        let appSupport = try! fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        
        let appFolder = appSupport.appendingPathComponent("SafeSync", isDirectory: true)
        
        if !fileManager.fileExists(atPath: appFolder.path) {
            try? fileManager.createDirectory(at: appFolder, withIntermediateDirectories: true)
        }
        
        self.storeURL = appFolder.appendingPathComponent("history.json")
        
        load()
    }
    
    func entries(forPlanID planID: UUID) -> [HistoryEntry] {
        entries
            .filter { $0.planID == planID }
            .sorted { $0.startedAt > $1.startedAt }
    }
    
    func addEntry(_ entry: HistoryEntry) {
        entries.append(entry)
        pruneOldEntries(forPlanID: entry.planID)
        save()
    }
    
    func clearHistory(forPlanID planID: UUID) {
        entries.removeAll { $0.planID == planID }
        save()
    }
    
    func removeEntries(forPlanID planID: UUID) {
        clearHistory(forPlanID: planID)
    }
    
    private func pruneOldEntries(forPlanID planID: UUID) {
        let planEntries = entries
            .filter { $0.planID == planID }
            .sorted { $0.startedAt > $1.startedAt }
        
        if planEntries.count > maxEntriesPerPlan {
            let toRemove = planEntries.dropFirst(maxEntriesPerPlan)
            let idsToRemove = Set(toRemove.map { $0.id })
            entries.removeAll { idsToRemove.contains($0.id) }
        }
    }
    
    private func load() {
        guard fileManager.fileExists(atPath: storeURL.path) else {
            entries = []
            return
        }
        
        do {
            let data = try Data(contentsOf: storeURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            entries = try decoder.decode([HistoryEntry].self, from: data)
        } catch {
            print("Error loading history: \(error.localizedDescription)")
            entries = []
        }
    }
    
    private func save() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(entries)
            try data.write(to: storeURL, options: [.atomic])
        } catch {
            print("Error saving history: \(error.localizedDescription)")
        }
    }
}