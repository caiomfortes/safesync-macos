//
//  StandalonePreviewWindow.swift
//  SafeSync2
//
//  Created by Caio Gabriel de Moura Fortes on 09/04/26.
//


import SwiftUI
import AppKit

struct StandalonePreviewWindow: View {
    let coordinator: BackupCoordinator
    
    @Environment(\.dismissWindow) private var dismissWindow
    
    private var pendingExecution: BackupExecution? {
        coordinator.executions.first { execution in
            execution.originatedFromPopover &&
            { if case .waitingConfirmation = execution.progress.phase { return true } else { return false } }()
        }
    }
    
    @State private var pendingConfirmExecutionID: UUID? = nil
    
    var body: some View {
        Group {
            if let execution = pendingExecution, let previewData = execution.previewData {
                BackupPreviewSheet(
                    data: previewData,
                    onCancel: {
                        coordinator.cancelExecution(executionID: execution.id)
                        dismissWindow(id: "preview")
                    },
                    onConfirm: {
                        if previewData.result.orphans.isEmpty {
                            coordinator.confirmExecution(executionID: execution.id)
                            dismissWindow(id: "preview")
                        } else {
                            pendingConfirmExecutionID = execution.id
                        }
                    }
                )
            } else {
                VStack {
                    ProgressView()
                    Text("Loading preview...")
                        .font(DesignFont.body)
                        .foregroundStyle(Color.dsTextSecondary)
                        .padding(.top, DesignSpacing.md)
                }
                .frame(width: 400, height: 200)
            }
        }
        .background {
            WindowAccessor { window in
                window.level = .floating
                window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
                window.center()
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
        .alert(
            "Confirm file removal?",
            isPresented: Binding(
                get: { pendingConfirmExecutionID != nil },
                set: { if !$0 { pendingConfirmExecutionID = nil } }
            ),
            presenting: pendingConfirmExecutionID
        ) { executionID in
            Button("Cancel", role: .cancel) {
                pendingConfirmExecutionID = nil
            }
            Button("Continue", role: .destructive) {
                coordinator.confirmExecution(executionID: executionID)
                pendingConfirmExecutionID = nil
                dismissWindow(id: "preview")
            }
        } message: { _ in
            if let count = pendingExecution?.previewData?.result.orphans.count {
                Text("This operation will move \(count) file(s) or folder(s) from the destination to the Trash. You can recover them from the Trash if you change your mind. Continue?")
            }
        }
    }
}

struct WindowAccessor: NSViewRepresentable {
    let configure: (NSWindow) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                configure(window)
            }
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}
