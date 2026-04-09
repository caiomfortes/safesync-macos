//
//  SettingsView.swift
//  SafeSync2
//
//  Created by Caio Gabriel de Moura Fortes on 09/04/26.
//


import SwiftUI

struct SettingsView: View {
    @AppStorage("appearanceMode") private var appearanceModeRaw: String = AppearanceMode.system.rawValue
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    
    var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
        }
        .frame(width: 500, height: 380)
    }
    
    private var generalTab: some View {
        Form {
            Section {
                Picker("Appearance", selection: $appearanceModeRaw) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.label).tag(mode.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Appearance")
                    .font(DesignFont.headline)
            } footer: {
                Text("Choose how the app should look. \"Follow system\" matches your macOS appearance settings.")
                    .font(DesignFont.caption)
                    .foregroundStyle(Color.dsTextSecondary)
            }
            
            Section {
                Toggle("Show notifications", isOn: $notificationsEnabled)
            } header: {
                Text("Notifications")
                    .font(DesignFont.headline)
            } footer: {
                Text("Get notified when backups complete, fail, or are cancelled. Notifications won't appear when the SafeSync window is in focus.")
                    .font(DesignFont.caption)
                    .foregroundStyle(Color.dsTextSecondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

#Preview {
    SettingsView()
}
