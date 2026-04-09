//
//  NotificationService.swift
//  SafeSync2
//
//  Created by Caio Gabriel de Moura Fortes on 09/04/26.
//


import Foundation
import UserNotifications
import AppKit

@MainActor
final class NotificationService {
    
    static let shared = NotificationService()
    
    private var permissionGranted: Bool = false
    private var permissionRequested: Bool = false
    
    private init() {}
    
    func requestPermissionIfNeeded() async {
        guard !permissionRequested else { return }
        permissionRequested = true
        
        let center = UNUserNotificationCenter.current()
        
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound])
            permissionGranted = granted
        } catch {
            permissionGranted = false
        }
    }
    
    func notifyBackupCompleted(planName: String, copied: Int, updated: Int, orphansRemoved: Int) {
        guard shouldNotify() else { return }
        
        var body = ""
        var parts: [String] = []
        if copied > 0 { parts.append(String(localized: "\(copied) new")) }
        if updated > 0 { parts.append(String(localized: "\(updated) updated")) }
        if orphansRemoved > 0 { parts.append(String(localized: "\(orphansRemoved) removed")) }
        
        if parts.isEmpty {
            body = String(localized: "Nothing to do — already up to date")
        } else {
            body = parts.joined(separator: ", ")
        }
        
        send(
            title: String(localized: "Backup completed"),
            subtitle: planName,
            body: body
        )
    }
    
    func notifyBackupFailed(planName: String, errorMessage: String) {
        guard shouldNotify() else { return }
        
        send(
            title: String(localized: "Backup failed"),
            subtitle: planName,
            body: errorMessage
        )
    }
    
    func notifyBackupCancelled(planName: String) {
        guard shouldNotify() else { return }
        
        send(
            title: String(localized: "Backup cancelled"),
            subtitle: planName,
            body: String(localized: "Operation was cancelled")
        )
    }
    
    // MARK: - Helpers
    
    private func shouldNotify() -> Bool {
        let notificationsEnabled = UserDefaults.standard.object(forKey: "notificationsEnabled") as? Bool ?? true
        guard notificationsEnabled else { return false }
        
        if NSApp.isActive,
           let mainWindow = NSApp.mainWindow,
           mainWindow.isVisible,
           mainWindow.isKeyWindow {
            return false
        }
        
        return true
    }
    
    private func send(title: String, subtitle: String, body: String) {
        Task {
            await requestPermissionIfNeeded()
            
            guard permissionGranted else { return }
            
            let content = UNMutableNotificationContent()
            content.title = title
            content.subtitle = subtitle
            content.body = body
            content.sound = .default
            
            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil
            )
            
            try? await UNUserNotificationCenter.current().add(request)
        }
    }
}
