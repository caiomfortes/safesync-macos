//
//  AboutView.swift
//  SafeSync2
//
//  Created by Caio Gabriel de Moura Fortes on 09/04/26.
//


import SwiftUI

struct AboutView: View {
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var body: some View {
        VStack(spacing: DesignSpacing.lg) {
            Image(systemName: "externaldrive.fill.badge.timemachine")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(Color.dsAccent)
                .padding(.top, DesignSpacing.xl)
            
            VStack(spacing: DesignSpacing.xs) {
                Text("SafeSync")
                    .font(DesignFont.largeTitle)
                    .foregroundStyle(Color.dsTextPrimary)
                
                Text("Version \(appVersion) (\(buildNumber))")
                    .font(DesignFont.caption)
                    .foregroundStyle(Color.dsTextSecondary)
            }
            
            Text("Safe and predictable incremental backups for macOS.")
                .font(DesignFont.body)
                .foregroundStyle(Color.dsTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSpacing.xl)
            
            Spacer()
            
            Text("Made with care.")
                .font(DesignFont.caption)
                .foregroundStyle(Color.dsTextSecondary)
                .padding(.bottom, DesignSpacing.lg)
        }
        .frame(width: 360, height: 380)
        .background(Color.dsSurfaceSecondary)
    }
}

#Preview {
    AboutView()
}