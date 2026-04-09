import Foundation
import Observation

@Observable
@MainActor
final class BackupCoordinator {
    
    private(set) var executions: [BackupExecution] = []
    
    private let store: PlanStore
    private var runningTasks: [UUID: Task<Void, Never>] = [:]
    private let maxConcurrent = 3
    
    init(store: PlanStore) {
        self.store = store
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
    
    func startAnalysis(for plan: BackupPlan) {
        if execution(forPlanID: plan.id) != nil {
            return
        }
        
        let initialPhase: BackupProgress.Phase = canStartNewExecution() ? .analyzing : .queued
        
        let execution = BackupExecution(
            planID: plan.id,
            planName: plan.name,
            progress: BackupProgress(
                phase: initialPhase,
                filesProcessed: 0,
                filesTotal: 0,
                bytesProcessed: 0,
                bytesTotal: 0,
                startedAt: Date()
            )
        )
        
        executions.append(execution)
        
        if case .analyzing = initialPhase {
            let task = Task { [weak self] in
                guard let self else { return }
                await self.runAnalysis(executionID: execution.id, plan: plan)
            }
            runningTasks[execution.id] = task
        }
    }
    
    func confirmExecution(executionID: UUID) {
        guard let index = executions.firstIndex(where: { $0.id == executionID }) else { return }
        guard let plan = store.plans.first(where: { $0.id == executions[index].planID }) else { return }
        guard let previewData = executions[index].previewData else { return }
        
        executions[index].progress.phase = .copying
        executions[index].progress.filesTotal = previewData.result.newFiles.count + previewData.result.updatedFiles.count
        executions[index].progress.bytesTotal = previewData.totalSize ?? 0
        executions[index].progress.startedAt = Date()
        
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
                destination: resolved.destinationURL
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
            
            updateExecution(id: executionID) { execution in
                execution.progress.phase = .completed
            }

            if let updatedPlan = store.plans.first(where: { $0.id == plan.id }) {
                store.updatePlan(updatedPlan.withLastRun(Date()))
            }

            _ = report

            dequeueNext()

            Task { [weak self] in
                try? await Task.sleep(for: .seconds(5))
                guard let self else { return }
                self.removeExecution(executionID: executionID)
            }
        } catch {
            updateExecution(id: executionID) { execution in
                execution.progress.phase = .failed("Erro: \(error.localizedDescription)")
            }
            dequeueNext()
        }
        
        runningTasks[executionID] = nil
    }
    
    // MARK: - Helpers
    
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
            case .analyzing, .copying, .finishing:
                return true
            case .queued, .waitingConfirmation, .completed, .failed, .cancelled:
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
        
        executions[nextIndex].progress.phase = .analyzing
        executions[nextIndex].progress.startedAt = Date()
        
        let executionID = execution.id
        let task = Task { [weak self] in
            guard let self else { return }
            await self.runAnalysis(executionID: executionID, plan: plan)
        }
        runningTasks[executionID] = task
    }
}
