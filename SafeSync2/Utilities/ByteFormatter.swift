//
//  ByteFormatter.swift
//  SafeSync2
//
//  Created by Caio Gabriel de Moura Fortes on 07/04/26.
//


import Foundation

enum ByteFormatter {
    
    static func humanReadable(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
