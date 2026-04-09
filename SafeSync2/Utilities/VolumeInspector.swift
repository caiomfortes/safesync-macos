//
//  VolumeInspector.swift
//  SafeSync2
//
//  Created by Caio Gabriel de Moura Fortes on 07/04/26.
//


import Foundation

enum VolumeInspector {
    
    static func areOnSameVolume(_ urlA: URL, _ urlB: URL) -> Bool {
        guard
            let idA = try? urlA.resourceValues(forKeys: [.volumeIdentifierKey]).volumeIdentifier,
            let idB = try? urlB.resourceValues(forKeys: [.volumeIdentifierKey]).volumeIdentifier
        else {
            return false
        }
        
        return (idA as? AnyHashable) == (idB as? AnyHashable)
    }
    
    static func availableCapacity(at url: URL) -> Int64? {
        guard let values = try? url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]),
              let capacity = values.volumeAvailableCapacityForImportantUsage else {
            return nil
        }
        return capacity
    }
    
    static func totalSize(of actions: [BackupAction]) async -> Int64 {
        var total: Int64 = 0
        
        for action in actions {
            let url: URL
            switch action {
            case .copyNew(let source, _, _):
                url = source
            case .updateExisting(let source, _, _):
                url = source
            case .skipUnchanged:
                continue
            }
            
            if let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                total += Int64(size)
            }
        }
        
        return total
    }
}