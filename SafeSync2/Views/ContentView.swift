import SwiftUI

struct ContentView: View {
    let store: PlanStore
    let coordinator: BackupCoordinator
    
    @State private var isChoosingPlanType = false
    @State private var pendingPlanType: PlanType? = nil
    @State private var planPendingDeletion: BackupPlan? = nil
    
    private enum PlanType {
        case backup
        case mirror
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Group {
                if store.plans.isEmpty {
                    EmptyStateView(onCreatePlan: {
                        isChoosingPlanType = true
                    })
                } else {
                    NavigationSplitView {
                        PlanSidebar(
                            store: store,
                            onCreatePlan: { isChoosingPlanType = true },
                            onDeletePlan: { plan in planPendingDeletion = plan }
                        )
                        .navigationSplitViewColumnWidth(min: 220, ideal: 260)
                    } detail: {
                        if let selected = store.selectedPlan {
                            PlanDetailView(plan: selected, store: store, coordinator: coordinator)
                        } else {
                            Text("Selecione um plano")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                }
            }
            
            GlobalStatusBar(coordinator: coordinator, store: store)
                .animation(.easeInOut(duration: 0.25), value: coordinator.executions.count)
        }
        .frame(minWidth: 900, minHeight: 600)
        .sheet(isPresented: $isChoosingPlanType) {
            PlanTypeChooserSheet(
                onCancel: {
                    isChoosingPlanType = false
                },
                onChooseBackup: {
                    isChoosingPlanType = false
                    pendingPlanType = .backup
                },
                onChooseMirror: {
                    isChoosingPlanType = false
                    pendingPlanType = .mirror
                }
            )
        }
        .sheet(isPresented: Binding(
            get: { pendingPlanType != nil },
            set: { if !$0 { pendingPlanType = nil } }
        )) {
            if let type = pendingPlanType {
                CreatePlanSheet(
                    isMirrorMode: type == .mirror,
                    onCancel: {
                        pendingPlanType = nil
                    },
                    onCreate: { name, sources, destination, isMirror in
                        createPlan(name: name, sources: sources, destination: destination, isMirror: isMirror)
                    }
                )
            }
        }
        .alert(
            "Apagar plano?",
            isPresented: Binding(
                get: { planPendingDeletion != nil },
                set: { if !$0 { planPendingDeletion = nil } }
            ),
            presenting: planPendingDeletion
        ) { plan in
            Button("Apagar", role: .destructive) {
                store.removePlan(id: plan.id)
                planPendingDeletion = nil
            }
            Button("Cancelar", role: .cancel) {
                planPendingDeletion = nil
            }
        } message: { plan in
            Text("Tem certeza que deseja apagar o plano \"\(plan.name)\"? Essa ação não pode ser desfeita. Os arquivos já copiados no destino não serão afetados.")
        }
    }
    
    private func createPlan(name: String, sources: [URL], destination: URL, isMirror: Bool) {
        do {
            let plan = try BackupPlan.create(
                name: name,
                sourceURLs: sources,
                destinationURL: destination,
                isMirrorMode: isMirror
            )
            store.addPlan(plan)
            pendingPlanType = nil
        } catch {
            print("Erro ao criar plano: \(error.localizedDescription)")
        }
    }
}

#Preview {
    let store = PlanStore()
    let coordinator = BackupCoordinator(store: store)
    return ContentView(store: store, coordinator: coordinator)
}
