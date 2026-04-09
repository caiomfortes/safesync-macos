//
//  PlanStore.swift
//  SafeSync2
//
//  Created by Caio Gabriel de Moura Fortes on 07/04/26.
//

import Foundation
import Observation

@Observable
final class PlanStore {
    
    private(set) var plans: [BackupPlan] = []
    
    var selectedPlanID: UUID?

    
    
    private let fileManager = FileManager.default
    private let storeURL: URL
    private let selectedIDURL: URL
    
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
        
        self.storeURL = appFolder.appendingPathComponent("plans.json")
        self.selectedIDURL = appFolder.appendingPathComponent("selected.json")
        
        load()
        loadSelectedID()
    }
    
    func selectPlan(id: UUID?) {
        selectedPlanID = id
        saveSelectedID()
    }
    
    var selectedPlan: BackupPlan? {
        guard let id = selectedPlanID else { return nil }
        return plans.first { $0.id == id }
    }
    
    func addPlan(_ plan: BackupPlan) {
        plans.append(plan)
        selectPlan(id: plan.id)
        save()
    }
    
    func updatePlan(_ plan: BackupPlan) {
        if let index = plans.firstIndex(where: { $0.id == plan.id }) {
            plans[index] = plan
            save()
        }
    }
    
    func removePlan(id: UUID) {
        plans.removeAll { $0.id == id }
        
        if selectedPlanID == id {
            selectPlan(id: plans.first?.id)
        }
        
        save()
    }
    
    private func load() {
        guard fileManager.fileExists(atPath: storeURL.path) else {
            plans = []
            return
        }
        
        do {
            let data = try Data(contentsOf: storeURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            plans = try decoder.decode([BackupPlan].self, from: data)
        } catch {
            print("Erro ao carregar planos: \(error.localizedDescription)")
            plans = []
        }
    }
    
    private func save() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(plans)
            try data.write(to: storeURL, options: [.atomic])
        } catch {
            print("Erro ao salvar planos: \(error.localizedDescription)")
        }
    }
    
    private func loadSelectedID() {
        guard fileManager.fileExists(atPath: selectedIDURL.path) else {
            selectedPlanID = plans.first?.id
            return
        }
        
        do {
            let data = try Data(contentsOf: selectedIDURL)
            let id = try JSONDecoder().decode(UUID.self, from: data)
            if plans.contains(where: { $0.id == id }) {
                selectedPlanID = id
            } else {
                selectedPlanID = plans.first?.id
            }
        } catch {
            selectedPlanID = plans.first?.id
        }
    }
    
    private func saveSelectedID() {
        do {
            if let id = selectedPlanID {
                let data = try JSONEncoder().encode(id)
                try data.write(to: selectedIDURL, options: [.atomic])
            } else if fileManager.fileExists(atPath: selectedIDURL.path) {
                try fileManager.removeItem(at: selectedIDURL)
            }
        } catch {
            print("Erro ao salvar ID selecionado: \(error.localizedDescription)")
        }
    }
}

