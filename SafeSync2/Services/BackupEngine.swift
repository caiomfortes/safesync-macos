//
//  BackupEngine.swift
//  SafeSync2
//
//  Created by Caio Gabriel de Moura Fortes on 07/04/26.
//

import Foundation


final class BackupEngine {
    
    private let fileManager = FileManager.default
    private let maxDepth = 255
    
    func analyze(sources: [URL], destination: URL) async -> BackupPlanResult {
        var actions: [BackupAction] = []
        var skippedSymlinks: [URL] = []
        var errors: [String] = []
        
        for sourceRoot in sources {
            let sourceName = sourceRoot.lastPathComponent
            let destinationRoot = destination.appendingPathComponent(sourceName)
            
            walk(
                source: sourceRoot,
                sourceRoot: sourceRoot,
                destinationRoot: destinationRoot,
                depth: 0,
                actions: &actions,
                skippedSymlinks: &skippedSymlinks,
                errors: &errors
            )
        }
        
        return BackupPlanResult(
            actions: actions,
            skippedSymlinks: skippedSymlinks,
            errors: errors
        )
    }
    
    private func walk(
        source: URL,
        sourceRoot: URL,
        destinationRoot: URL,
        depth: Int,
        actions: inout [BackupAction],
        skippedSymlinks: inout [URL],
        errors: inout [String]
    ) {
        guard depth <= maxDepth else {
            errors.append("Profundidade máxima excedida em \(source.path)")
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
            errors.append("Não consegui ler \(source.path): \(error.localizedDescription)")
            return
        }
        
        if values.isSymbolicLink == true {
            skippedSymlinks.append(source)
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
                errors.append("Não consegui listar \(source.path): \(error.localizedDescription)")
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
                    actions: &actions,
                    skippedSymlinks: &skippedSymlinks,
                    errors: &errors
                )
            }
            return
        }
        
        if values.isRegularFile == true {
            let relativePath = relativePath(from: sourceRoot, to: source)
            
            if fileManager.fileExists(atPath: destinationRoot.path) {
                if isSourceNewer(source: source, destination: destinationRoot) {
                    actions.append(.updateExisting(source: source, sourceRoot: sourceRoot, relativePath: relativePath))
                } else {
                    actions.append(.skipUnchanged(relativePath: relativePath))
                }
            } else {
                actions.append(.copyNew(source: source, sourceRoot: sourceRoot, relativePath: relativePath))
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
    
    func execute(result: BackupPlanResult, destination: URL) async -> BackupExecutionReport {
        var copied = 0
        var updated = 0
        var failed: [String] = []
        
        for action in result.actions {
            switch action {
            case .copyNew(let source, let sourceRoot, let relativePath):
                let target = destination
                    .appendingPathComponent(sourceRoot.lastPathComponent)
                    .appendingPathComponent(relativePath)
                if atomicCopy(from: source, to: target, errors: &failed) {
                    copied += 1
                }
                
            case .updateExisting(let source, let sourceRoot, let relativePath):
                let target = destination
                    .appendingPathComponent(sourceRoot.lastPathComponent)
                    .appendingPathComponent(relativePath)
                if atomicCopy(from: source, to: target, errors: &failed) {
                    updated += 1
                }
                
            case .skipUnchanged:
                continue
            }
        }
        
        return BackupExecutionReport(copied: copied, updated: updated, failures: failed)
    }

    private func atomicCopy(from source: URL, to target: URL, errors: inout [String]) -> Bool {
        let parent = target.deletingLastPathComponent()
        
        do {
            try fileManager.createDirectory(at: parent, withIntermediateDirectories: true)
        } catch {
            errors.append("Não criou diretório \(parent.path): \(error.localizedDescription)")
            return false
        }
        
        let tempTarget = parent.appendingPathComponent(target.lastPathComponent + ".tmp")
        
        if fileManager.fileExists(atPath: tempTarget.path) {
            try? fileManager.removeItem(at: tempTarget)
        }
        
        do {
            try fileManager.copyItem(at: source, to: tempTarget)
        } catch {
            errors.append("Falha ao copiar \(source.path): \(error.localizedDescription)")
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
            errors.append("Falha ao finalizar \(target.path): \(error.localizedDescription)")
            try? fileManager.removeItem(at: tempTarget)
            return false
        }
    }
}
