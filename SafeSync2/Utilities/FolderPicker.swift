//
//  FolderPicker.swift
//  SafeSync2
//
//  Created by Caio Gabriel de Moura Fortes on 07/04/26.
//

import AppKit

enum FolderPicker{
    static func pickerFolder(prompt: String) -> URL? {
        let panel = NSOpenPanel()
        panel.title = prompt
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        
        let response = panel.runModal()
        guard response == .OK else { return nil }
        return panel.url
    }
}
