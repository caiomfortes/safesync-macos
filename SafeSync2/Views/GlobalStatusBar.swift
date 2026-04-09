//
//  GlobalStatusBar.swift
//  SafeSync2
//
//  Created by Caio Gabriel de Moura Fortes on 08/04/26.
//


import SwiftUI

struct GlobalStatusBar: View {
    let coordinator: BackupCoordinator
    let store: PlanStore
    
    private var visibleExecutions: [BackupExecution] {
        coordinator.executions.filter { execution in
            switch execution.progress.phase {
            case .queued, .analyzing, .copying, .finishing:
                return true
            case .waitingConfirmation, .completed, .failed, .cancelled:
                return false
            }
        }
    }
    
    var body: some View {
        if !visibleExecutions.isEmpty {
            VStack(spacing: 0) {
                Divider()
                
                HStack(spacing: 16) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundStyle(.tint)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(visibleExecutions) { execution in
                            ExecutionRow(
                                execution: execution,
                                onCancel: {
                                    coordinator.cancelExecution(executionID: execution.id)
                                },
                                onSelect: {
                                    store.selectPlan(id: execution.planID)
                                }
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.bar)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

private struct ExecutionRow: View {
    let execution: BackupExecution
    let onCancel: () -> Void
    let onSelect: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onSelect) {
                Text(execution.planName)
                    .font(.callout)
                    .bold()
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
            
            phaseLabel
            
            if showsProgress {
                ProgressView(value: execution.progress.byteFraction)
                    .progressViewStyle(.linear)
                    .frame(maxWidth: 200)
                
                Text("\(Int(execution.progress.byteFraction * 100))%")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 36, alignment: .trailing)
            }
            
            if let remaining = remainingText {
                Text(remaining)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button(action: onCancel) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Cancelar")
        }
    }
    
    private var showsProgress: Bool {
        if case .copying = execution.progress.phase { return true }
        return false
    }
    
    private var remainingText: String? {
        guard case .copying = execution.progress.phase,
              let remaining = execution.progress.estimatedSecondsRemaining,
              remaining > 1 else {
            return nil
        }
        return "~\(TimeFormatter.humanReadable(seconds: remaining))"
    }
    
    @ViewBuilder
    private var phaseLabel: some View {
        switch execution.progress.phase {
        case .queued:
            Text("na fila")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .analyzing:
            Text("analisando")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .copying:
            Text("\(execution.progress.filesProcessed)/\(execution.progress.filesTotal)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        case .finishing:
            Text("finalizando")
                .font(.caption)
                .foregroundStyle(.secondary)
        default:
            EmptyView()
        }
    }
}