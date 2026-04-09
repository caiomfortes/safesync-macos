//
//  MenuBarPopover.swift
//  SafeSync2
//
//  Created by Caio Gabriel de Moura Fortes on 09/04/26.
//


import SwiftUI
import AppKit

struct MenuBarPopover: View {
    let store: PlanStore
    let coordinator: BackupCoordinator
    let historyStore: HistoryStore
    
    @Environment(\.openWindow) private var openWindow
    
    private var activeExecutions: [BackupExecution] {
        coordinator.executions.filter { execution in
            switch execution.progress.phase {
            case .analyzing, .copying, .finishing, .queued:
                return true
            default:
                return false
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            
            Divider()
            
            if store.plans.isEmpty && activeExecutions.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignSpacing.md) {
                        if !activeExecutions.isEmpty {
                            activeSection
                        }
                        
                        if !store.plans.isEmpty {
                            plansSection
                        }
                    }
                    .padding(DesignSpacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minHeight: 100, maxHeight: 400)
            }
            
            Divider()
            
            footer
        }
        .frame(width: 340)
        .background(Color.dsSurfaceSecondary)
    }
    
    // MARK: - Sections
    
    private var header: some View {
        HStack(spacing: DesignSpacing.sm) {
            Image(systemName: "externaldrive.fill.badge.timemachine")
                .foregroundStyle(Color.dsAccent)
                .font(.title3)
            
            Text("SafeSync")
                .font(DesignFont.headline)
                .foregroundStyle(Color.dsTextPrimary)
            
            Spacer()
        }
        .padding(DesignSpacing.md)
    }
    
    private var emptyState: some View {
        VStack(spacing: DesignSpacing.sm) {
            Image(systemName: "externaldrive")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(Color.dsTextSecondary)
            
            Text("No plans yet")
                .font(DesignFont.body)
                .foregroundStyle(Color.dsTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSpacing.xl)
    }
    
    private var activeSection: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.sm) {
            Text("Running")
                .font(DesignFont.caption)
                .foregroundStyle(Color.dsTextSecondary)
                .textCase(.uppercase)
            
            VStack(spacing: DesignSpacing.sm) {
                ForEach(activeExecutions) { execution in
                    ActiveExecutionRow(
                        execution: execution,
                        onCancel: {
                            coordinator.cancelExecution(executionID: execution.id)
                        }
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: activeExecutions.count)
        }
    }
    
    private var plansSection: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.sm) {
            Text("Plans")
                .font(DesignFont.caption)
                .foregroundStyle(Color.dsTextSecondary)
                .textCase(.uppercase)
            
            VStack(spacing: DesignSpacing.xs) {
                ForEach(store.plans) { plan in
                    PlanQuickRow(
                        plan: plan,
                        isRunning: coordinator.isRunning(planID: plan.id),
                        onRun: {
                            coordinator.startAnalysis(for: plan, fromPopover: true)
                        }
                    )
                }
            }
        }
    }
    
    private var footer: some View {
        HStack(spacing: DesignSpacing.sm) {
            Button {
                openMainWindow()
            } label: {
                Label("Open SafeSync", systemImage: "macwindow")
                    .font(DesignFont.body)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.dsAccent)
            
            Spacer()
            
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Text("Quit")
                    .font(DesignFont.caption)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.dsTextSecondary)
        }
        .padding(DesignSpacing.md)
    }
    
    // MARK: - Helpers
    
    private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        
        // Tenta achar uma janela já existente
        let existingWindow = NSApp.windows.first { window in
            window.contentViewController != nil &&
            window.canBecomeMain &&
            !(window.identifier?.rawValue.contains("settings") ?? false)
        }
        
        if let window = existingWindow {
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
        } else {
            // Janela não existe, abre uma nova via openWindow
            openWindow(id: "main")
        }
    }
}



private struct ActiveExecutionRow: View {
    let execution: BackupExecution
    let onCancel: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.xs) {
            HStack(spacing: DesignSpacing.xs) {
                Text(execution.planName)
                    .font(DesignFont.body)
                    .foregroundStyle(Color.dsTextPrimary)
                    .lineLimit(1)
                
                Spacer()
                
                phaseLabel
                
                Button(action: onCancel) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(Color.dsTextSecondary)
                }
                .buttonStyle(.plain)
                .help("Cancel")
            }
            
            if showsProgress {
                ProgressView(value: execution.progress.byteFraction)
                    .progressViewStyle(.linear)
                    .tint(Color.dsAccent)
            }
        }
        .padding(DesignSpacing.sm)
        .background(Color.dsSurfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: DesignRadius.sm))
    }
    
    private var showsProgress: Bool {
        if case .copying = execution.progress.phase { return true }
        return false
    }
    
    @ViewBuilder
    private var phaseLabel: some View {
        switch execution.progress.phase {
        case .queued:
            Text("queued")
                .font(DesignFont.caption)
                .foregroundStyle(Color.dsTextSecondary)
        case .analyzing:
            Text("analyzing")
                .font(DesignFont.caption)
                .foregroundStyle(Color.dsTextSecondary)
        case .copying:
            Text("\(Int(execution.progress.byteFraction * 100))%")
                .font(DesignFont.caption.monospacedDigit())
                .foregroundStyle(Color.dsAccent)
        case .finishing:
            Text("finishing")
                .font(DesignFont.caption)
                .foregroundStyle(Color.dsTextSecondary)
        default:
            EmptyView()
        }
    }
}

private struct PlanQuickRow: View {
    let plan: BackupPlan
    let isRunning: Bool
    let onRun: () -> Void
    
    private var iconName: String {
        plan.isMirrorMode ? "arrow.triangle.2.circlepath" : "externaldrive.fill"
    }
    
    private var iconColor: Color {
        plan.isMirrorMode ? Color.dsWarning : Color.dsAccent
    }
    
    private var statusText: String {
        if let lastRun = plan.lastRunAt {
            return lastRun.formatted(.relative(presentation: .named))
        }
        return String(localized: "Never run")
    }
    
    var body: some View {
        HStack(spacing: DesignSpacing.sm) {
            Image(systemName: iconName)
                .foregroundStyle(iconColor)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(plan.name)
                    .font(DesignFont.body)
                    .foregroundStyle(Color.dsTextPrimary)
                    .lineLimit(1)
                
                Text(statusText)
                    .font(DesignFont.caption)
                    .foregroundStyle(Color.dsTextSecondary)
            }
            
            Spacer()
            
            Button(action: onRun) {
                Image(systemName: "play.fill")
                    .font(.caption)
                    .foregroundStyle(Color.dsAccent)
            }
            .buttonStyle(.plain)
            .disabled(isRunning)
            .opacity(isRunning ? 0.3 : 1)
        }
        .padding(.horizontal, DesignSpacing.sm)
        .padding(.vertical, 6)
        .background(Color.dsSurfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: DesignRadius.sm))
    }
}
