//
//  TimeFormatter.swift
//  SafeSync2
//
//  Created by Caio Gabriel de Moura Fortes on 08/04/26.
//


import Foundation

enum TimeFormatter {
    
    static func humanReadable(seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        
        if total < 60 {
            return "\(total)s"
        } else if total < 3600 {
            let minutes = total / 60
            let secs = total % 60
            return "\(minutes)min \(secs)s"
        } else {
            let hours = total / 3600
            let minutes = (total % 3600) / 60
            return "\(hours)h \(minutes)min"
        }
    }
}