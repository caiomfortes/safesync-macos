import Foundation
import Observation

@Observable
@MainActor
final class BackupCoordinator {
    
    private(set) var executions: [BackupExecution] = []
    
    private let store: PlanStore
    private let historyStore: HistoryStore
    private var runningTasks: [UUID: Task<Void, Never>] = [:]
    private let maxConcurrent = 3
    
    init(store: PlanStore, historyStore: HistoryStore) {
        self.store = store
        self.historyStore = historyStore
    }
    
    // MARK: - Queries
    
    func execution(forPlanID planID: UUID) -> BackupExecution? {
        executions.first { $0.planID == planID }
    }
    
    func isRunning(planID: UUID) -> Bool {
        guard let execution = execution(forPlanID: planID) else { return false }
        switch execution.progress.phase {
        case .queued, .analyzing, .copying, .finishing, .waitingConfirmation:
            return true
        case .completed, .failed, .cancelled:
            return false
        }
    }
    
    // MARK: - Lifecycle
    
    func startAnalysis(for plan: BackupPlan, fromPopover: Bool = false) {
        if let existing = execution(forPlanID: plan.id) {
            switch existing.progress.phase {
            case .queued, .analyzing, .waitingConfirmation, .copying, .finishing:
                return
            case .completed, .failed, .cancelled:
                removeExecution(executionID: existing.id)
            }
        }
        
        let execution = BackupExecution(
            planID: plan.id,
            planName: plan.name,
            progress: BackupProgress(
                phase: .analyzing,
                filesProcessed: 0,
                filesTotal: 0,
                bytesProcessed: 0,
                bytesTotal: 0,
                startedAt: Date()
            ),
            originatedFromPopover: fromPopover
        )
        
        executions.append(execution)
        
        let task = Task { [weak self] in
            guard let self else { return }
            await self.runAnalysis(executionID: execution.id, plan: plan)
        }
        runningTasks[execution.id] = task
    }
    
    func confirmExecution(executionID: UUID) {
        guard let index = executions.firstIndex(where: { $0.id == executionID }) else { return }
        guard let plan = store.plans.first(where: { $0.id == executions[index].planID }) else { return }
        guard let previewData = executions[index].previewData else { return }
        
        if canStartNewExecution() {
            startCopying(executionIndex: index, plan: plan, previewData: previewData)
        } else {
            executions[index].progress.phase = .queued
        }
    }

    private func startCopying(
        executionIndex: Int,
        plan: BackupPlan,
        previewData: BackupPreviewData
    ) {
        let executionID = executions[executionIndex].id
        
        executions[executionIndex].progress.phase = .copying
        executions[executionIndex].progress.filesTotal = previewData.result.newFiles.count + previewData.result.updatedFiles.count + previewData.result.orphans.count
        executions[executionIndex].progress.bytesTotal = previewData.totalSize ?? 0
        executions[executionIndex].progress.startedAt = Date()
        
        let task = Task { [weak self] in
            guard let self else { return }
            await self.runExecution(
                executionID: executionID,
                plan: plan,
                previewData: previewData
            )
        }
        runningTasks[executionID] = task
    }
    
    func cancelExecution(executionID: UUID) {
        runningTasks[executionID]?.cancel()
        runningTasks[executionID] = nil
        
        if let execution = executions.first(where: { $0.id == executionID }) {
            let isCopyingOrFinishing: Bool = {
                switch execution.progress.phase {
                case .copying, .finishing: return true
                default: return false
                }
            }()
            
            if isCopyingOrFinishing,
               let plan = store.plans.first(where: { $0.id == execution.planID }) {
                recordHistory(
                    executionID: executionID,
                    plan: plan,
                    outcome: .cancelled,
                    report: nil
                )
                
                NotificationService.shared.notifyBackupCancelled(planName: plan.name)
            }
        }
        
        if let index = executions.firstIndex(where: { $0.id == executionID }) {
            executions[index].progress.phase = .cancelled
        }
        
        dequeueNext()
        
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(3))
            guard let self else { return }
            self.removeExecution(executionID: executionID)
        }
    }
    
    func dismissExecution(executionID: UUID) {
        removeExecution(executionID: executionID)
    }
    
    private func removeExecution(executionID: UUID) {
        executions.removeAll { $0.id == executionID }
        runningTasks[executionID] = nil
    }
    
    // MARK: - Background work
    
    private func runAnalysis(executionID: UUID, plan: BackupPlan) async {
        do {
            let resolved = try plan.resolve()
            
            let activeURLs = activateAccess(
                sources: resolved.sourceURLs,
                destination: resolved.destinationURL
            )
            defer { releaseAccess(urls: activeURLs) }
            
            let engine = BackupEngine()
            let result = await engine.analyze(
                sources: resolved.sourceURLs,
                destination: resolved.destinationURL,
                isMirrorMode: plan.isMirrorMode
            )
            
            let sameVolume = resolved.sourceURLs.allSatisfy { source in
                VolumeInspector.areOnSameVolume(source, resolved.destinationURL)
            }
            
            var totalSize: Int64? = nil
            var availableSpace: Int64? = nil
            
            if !sameVolume {
                let actionsToMeasure = result.newFiles + result.updatedFiles
                totalSize = await VolumeInspector.totalSize(of: actionsToMeasure)
                availableSpace = VolumeInspector.availableCapacity(at: resolved.destinationURL)
            }
            
            let previewData = BackupPreviewData(
                planName: plan.name,
                result: result,
                sameVolume: sameVolume,
                totalSize: totalSize,
                availableSpace: availableSpace
            )
            
            updateExecution(id: executionID) { execution in
                execution.previewData = previewData
                execution.progress.phase = .waitingConfirmation
            }

            dequeueNext()
        } catch {
            updateExecution(id: executionID) { execution in
                execution.progress.phase = .failed("Erro na análise: \(error.localizedDescription)")
            }
            dequeueNext()
        }
        
        runningTasks[executionID] = nil
    }
    
    private func runExecution(
        executionID: UUID,
        plan: BackupPlan,
        previewData: BackupPreviewData
    ) async {
        do {
            let resolved = try plan.resolve()
            
            let activeURLs = activateAccess(
                sources: resolved.sourceURLs,
                destination: resolved.destinationURL
            )
            defer { releaseAccess(urls: activeURLs) }
            
            let engine = BackupEngine()
            let report = await engine.execute(
                result: previewData.result,
                sources: resolved.sourceURLs,
                destination: resolved.destinationURL,
                totalBytes: previewData.totalSize ?? 0,
                progressHandler: { [weak self] filesProcessed, bytesProcessed in
                    Task { @MainActor [weak self] in
                        self?.updateExecution(id: executionID) { execution in
                            execution.progress.filesProcessed = filesProcessed
                            execution.progress.bytesProcessed = bytesProcessed
                        }
                    }
                }
            )
            
            if Task.isCancelled {
                return
            }
            
            updateExecution(id: executionID) { execution in
                execution.progress.phase = .completed
            }
            
            if let updatedPlan = store.plans.first(where: { $0.id == plan.id }) {
                store.updatePlan(updatedPlan.withLastRun(Date()))
            }
            
            recordHistory(
                executionID: executionID,
                plan: plan,
                outcome: .completed,
                report: report
            )

            NotificationService.shared.notifyBackupCompleted(
                planName: plan.name,
                copied: report.copied,
                updated: report.updated,
                orphansRemoved: report.orphansRemoved
            )

            dequeueNext()
            
            Task { [weak self] in
                try? await Task.sleep(for: .seconds(5))
                guard let self else { return }
                self.removeExecution(executionID: executionID)
            }
        } catch {
            if Task.isCancelled {
                return
            }
            
            updateExecution(id: executionID) { execution in
                execution.progress.phase = .failed("Error: \(error.localizedDescription)")
            }
            recordHistory(
                executionID: executionID,
                plan: plan,
                outcome: .failed,
                report: nil,
                errorMessage: error.localizedDescription
            )

            NotificationService.shared.notifyBackupFailed(
                planName: plan.name,
                errorMessage: error.localizedDescription
            )

            dequeueNext()
        }
        
        runningTasks[executionID] = nil
    }
    
    // MARK: - Helpers
    
    private func recordHistory(
        executionID: UUID,
        plan: BackupPlan,
        outcome: HistoryEntry.Outcome,
        report: BackupExecutionReport?,
        errorMessage: String? = nil
    ) {
        guard let execution = executions.first(where: { $0.id == executionID }) else { return }
        
        let entry = HistoryEntry(
            planID: plan.id,
            planName: execution.planName,
            startedAt: execution.progress.startedAt,
            finishedAt: Date(),
            wasMirrorMode: plan.isMirrorMode,
            outcome: outcome,
            copiedCount: report?.copied ?? 0,
            updatedCount: report?.updated ?? 0,
            orphansRemovedCount: report?.orphansRemoved ?? 0,
            failureCount: report?.failures.count ?? 0,
            firstFailureMessage: errorMessage ?? report?.failures.first
        )
        
        historyStore.addEntry(entry)
    }
    
    private func updateExecution(id: UUID, mutation: (inout BackupExecution) -> Void) {
        if let index = executions.firstIndex(where: { $0.id == id }) {
            mutation(&executions[index])
        }
    }
    
    private func activateAccess(sources: [URL], destination: URL) -> [URL] {
        var active: [URL] = []
        for url in sources {
            if url.startAccessingSecurityScopedResource() {
                active.append(url)
            }
        }
        if destination.startAccessingSecurityScopedResource() {
            active.append(destination)
        }
        return active
    }
    
    private func releaseAccess(urls: [URL]) {
        for url in urls {
            url.stopAccessingSecurityScopedResource()
        }
    }
    
    private func activeExecutionCount() -> Int {
        executions.filter { execution in
            switch execution.progress.phase {
            case .copying, .finishing:
                return true
            case .queued, .analyzing, .waitingConfirmation, .completed, .failed, .cancelled:
                return false
            }
        }.count
    }

    private func canStartNewExecution() -> Bool {
        activeExecutionCount() < maxConcurrent
    }

    private func dequeueNext() {
        guard canStartNewExecution() else { return }
        
        guard let nextIndex = executions.firstIndex(where: { execution in
            if case .queued = execution.progress.phase {
                return true
            }
            return false
        }) else {
            return
        }
        
        let execution = executions[nextIndex]
        
        guard let plan = store.plans.first(where: { $0.id == execution.planID }) else {
            executions.remove(at: nextIndex)
            return
        }
        
        guard let previewData = execution.previewData else {
            executions.remove(at: nextIndex)
            return
        }
        
        startCopying(executionIndex: nextIndex, plan: plan, previewData: previewData)
    }
}
