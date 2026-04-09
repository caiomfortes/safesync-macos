//
//  BackupEngine.swift
//  SafeSync2
//
//  Created by Caio Gabriel de Moura Fortes on 07/04/26.
//

import Foundation


actor BackupEngine {
    
    private let fileManager = FileManager.default
    private let maxDepth = 255
    
    func analyze(sources: [URL], destination: URL) async -> BackupPlanResult {
        let collector = AnalysisCollector()
        
        for sourceRoot in sources {
            let destinationRoot = destinationRootPath(
                for: sourceRoot,
                allSources: sources,
                destination: destination
            )
            
            walk(
                source: sourceRoot,
                sourceRoot: sourceRoot,
                destinationRoot: destinationRoot,
                depth: 0,
                collector: collector
            )
        }
        
        return BackupPlanResult(
            actions: collector.actions,
            skippedSymlinks: collector.skippedSymlinks,
            errors: collector.errors
        )
    }

    private func walk(
        source: URL,
        sourceRoot: URL,
        destinationRoot: URL,
        depth: Int,
        collector: AnalysisCollector
    ) {
        guard depth <= maxDepth else {
            collector.errors.append("Profundidade máxima excedida em \(source.path)")
            return
        }
        
        let keys: [URLResourceKey] = [
            .isDirectoryKey,
            .isSymbolicLinkKey,
            .isRegularFileKey,
            .contentModificationDateKey
        ]
        
        let values: URLResourceValues
        do {
            values = try source.resourceValues(forKeys: Set(keys))
        } catch {
            collector.errors.append("Não consegui ler \(source.path): \(error.localizedDescription)")
            return
        }
        
        if values.isSymbolicLink == true {
            collector.skippedSymlinks.append(source)
            return
        }
        
        if values.isDirectory == true {
            let children: [URL]
            do {
                children = try fileManager.contentsOfDirectory(
                    at: source,
                    includingPropertiesForKeys: keys,
                    options: [.skipsHiddenFiles]
                )
            } catch {
                collector.errors.append("Não consegui listar \(source.path): \(error.localizedDescription)")
                return
            }
            
            for child in children {
                let relative = child.lastPathComponent
                let childDestination = destinationRoot.appendingPathComponent(relative)
                walk(
                    source: child,
                    sourceRoot: sourceRoot,
                    destinationRoot: childDestination,
                    depth: depth + 1,
                    collector: collector
                )
            }
            return
        }
        
        if values.isRegularFile == true {
            let relativePath = relativePath(from: sourceRoot, to: source)
            
            if fileManager.fileExists(atPath: destinationRoot.path) {
                if isSourceNewer(source: source, destination: destinationRoot) {
                    collector.actions.append(.updateExisting(source: source, sourceRoot: sourceRoot, relativePath: relativePath))
                } else {
                    collector.actions.append(.skipUnchanged(relativePath: relativePath))
                }
            } else {
                collector.actions.append(.copyNew(source: source, sourceRoot: sourceRoot, relativePath: relativePath))
            }
        }
    }
    
    private func relativePath(from root: URL, to file: URL) -> String {
        let rootComponents = root.pathComponents
        let fileComponents = file.pathComponents
        let relative = fileComponents.dropFirst(rootComponents.count)
        return relative.joined(separator: "/")
    }
    
    private func isSourceNewer(source: URL, destination: URL) -> Bool {
        do {
            let sourceDate = try source.resourceValues(forKeys: [.contentModificationDateKey])
                .contentModificationDate ?? .distantPast
            let destDate = try destination.resourceValues(forKeys: [.contentModificationDateKey])
                .contentModificationDate ?? .distantPast
            return sourceDate > destDate
        } catch {
            return true
        }
    }
    
    func execute(
        result: BackupPlanResult,
        sources: [URL],
        destination: URL,
        totalBytes: Int64,
        progressHandler: (@Sendable (Int, Int64) -> Void)? = nil
    ) async -> BackupExecutionReport {
        var copied = 0
        var updated = 0
        let collector = ExecutionCollector()
        
        let actionsToProcess = result.actions.filter { action in
            switch action {
            case .copyNew, .updateExisting: return true
            case .skipUnchanged: return false
            }
        }
        
        var filesProcessed = 0
        var bytesProcessed: Int64 = 0
        
        for action in actionsToProcess {
            if Task.isCancelled {
                collector.failures.append("Operação cancelada pelo usuário")
                break
            }
            
            let actionBytes = bytesOfAction(action)
            
            switch action {
            case .copyNew(let source, let sourceRoot, let relativePath):
                let destinationRoot = destinationRootPath(
                    for: sourceRoot,
                    allSources: sources,
                    destination: destination
                )
                let target = destinationRoot.appendingPathComponent(relativePath)
                if atomicCopy(from: source, to: target, collector: collector) {
                    copied += 1
                }
                
            case .updateExisting(let source, let sourceRoot, let relativePath):
                let destinationRoot = destinationRootPath(
                    for: sourceRoot,
                    allSources: sources,
                    destination: destination
                )
                let target = destinationRoot.appendingPathComponent(relativePath)
                if atomicCopy(from: source, to: target, collector: collector) {
                    updated += 1
                }
                
            case .skipUnchanged:
                continue
            }
            
            filesProcessed += 1
            bytesProcessed += actionBytes
            
            progressHandler?(filesProcessed, bytesProcessed)
        }
        
        return BackupExecutionReport(
            copied: copied,
            updated: updated,
            failures: collector.failures
        )
    }

    private func bytesOfAction(_ action: BackupAction) -> Int64 {
        let url: URL
        switch action {
        case .copyNew(let source, _, _): url = source
        case .updateExisting(let source, _, _): url = source
        case .skipUnchanged: return 0
        }
        
        if let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
            return Int64(size)
        }
        return 0
    }

    private func atomicCopy(from source: URL, to target: URL, collector: ExecutionCollector) -> Bool {
        let parent = target.deletingLastPathComponent()
        
        do {
            try fileManager.createDirectory(at: parent, withIntermediateDirectories: true)
        } catch {
            collector.failures.append("Não criou diretório \(parent.path): \(error.localizedDescription)")
            return false
        }
        
        let tempTarget = parent.appendingPathComponent(target.lastPathComponent + ".tmp")
        
        if fileManager.fileExists(atPath: tempTarget.path) {
            try? fileManager.removeItem(at: tempTarget)
        }
        
        do {
            try fileManager.copyItem(at: source, to: tempTarget)
        } catch {
            collector.failures.append("Falha ao copiar \(source.path): \(error.localizedDescription)")
            return false
        }
        
        do {
            if fileManager.fileExists(atPath: target.path) {
                _ = try fileManager.replaceItemAt(target, withItemAt: tempTarget)
            } else {
                try fileManager.moveItem(at: tempTarget, to: target)
            }
            return true
        } catch {
            collector.failures.append("Falha ao finalizar \(target.path): \(error.localizedDescription)")
            try? fileManager.removeItem(at: tempTarget)
            return false
        }
    }

    
    
    private func destinationRootPath(
        for sourceRoot: URL,
        allSources: [URL],
        destination: URL
    ) -> URL {
        if allSources.count == 1 {
            return destination
        } else {
            return destination.appendingPathComponent(sourceRoot.lastPathComponent)
        }
    }
    
    private final class AnalysisCollector {
        var actions: [BackupAction] = []
        var skippedSymlinks: [URL] = []
        var errors: [String] = []
    }

    private final class ExecutionCollector {
        var failures: [String] = []
    }
}



