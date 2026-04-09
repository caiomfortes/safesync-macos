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
                
                HStack(spacing: DesignSpacing.lg) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundStyle(Color.dsAccent)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: DesignSpacing.sm) {
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
                            .transition(.asymmetric(
                                        insertion: .move(edge: .leading).combined(with: .opacity),
                                        removal: .opacity
                                    ))
                        }
                    }
                    .animation(.easeInOut(duration: 0.25), value: visibleExecutions.count)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, DesignSpacing.lg)
                .padding(.vertical, DesignSpacing.md)
                .background(Color.dsSurfacePrimary)
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
        HStack(spacing: DesignSpacing.md) {
            Button(action: onSelect) {
                Text(execution.planName)
                    .font(DesignFont.headline)
                    .foregroundStyle(Color.dsTextPrimary)
            }
            .buttonStyle(.plain)
            
            phaseLabel
            
            if showsProgress {
                ProgressView(value: execution.progress.byteFraction)
                    .progressViewStyle(.linear)
                    .tint(Color.dsAccent)
                    .frame(maxWidth: 200)
                
                Text("\(Int(execution.progress.byteFraction * 100))%")
                    .font(DesignFont.caption.monospacedDigit())
                    .foregroundStyle(Color.dsTextSecondary)
                    .frame(width: 36, alignment: .trailing)
            }
            
            if let remaining = remainingText {
                Text(remaining)
                    .font(DesignFont.caption.monospacedDigit())
                    .foregroundStyle(Color.dsTextSecondary)
            }
            
            Spacer()
            
            Button(action: onCancel) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Color.dsTextSecondary)
            }
            .buttonStyle(.plain)
            .help("Cancel")
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
            Text("queued")
                .font(DesignFont.caption)
                .foregroundStyle(Color.dsTextSecondary)
        case .analyzing:
            Text("analyzing")
                .font(DesignFont.caption)
                .foregroundStyle(Color.dsTextSecondary)
        case .copying:
            Text("\(execution.progress.filesProcessed)/\(execution.progress.filesTotal)")
                .font(DesignFont.caption.monospacedDigit())
                .foregroundStyle(Color.dsTextSecondary)
        case .finishing:
            Text("finishing")
                .font(DesignFont.caption)
                .foregroundStyle(Color.dsTextSecondary)
        default:
            EmptyView()
        }
    }
}
