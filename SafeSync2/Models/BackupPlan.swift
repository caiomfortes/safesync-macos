//
//  BackupPlan.swift
//  SafeSync2
//
//  Created by Caio Gabriel de Moura Fortes on 07/04/26.
//


import Foundation

struct BackupPlan: Identifiable, Codable {
    
    let id: UUID
    var name: String
    var sourceBookmarks: [Data]
    var destinationBookmarks: Data
    
    
    init(name: String, sourceBookmarks: [Data], destinationBookmarks: Data){
        self.id = UUID()
        self.name = name
        self.sourceBookmarks = sourceBookmarks
        self.destinationBookmarks = destinationBookmarks
    }
}


