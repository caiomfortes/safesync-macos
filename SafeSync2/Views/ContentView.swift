import SwiftUI

struct ContentView: View {
    let store: PlanStore
    let coordinator: BackupCoordinator
    
    @State private var isCreatingPlan = false
    @State private var planPendingDeletion: BackupPlan? = nil
    
    var body: some View {
        Group {
            if store.plans.isEmpty {
                EmptyStateView(onCreatePlan: {
                    isCreatingPlan = true
                })
            } else {
                NavigationSplitView {
                    PlanSidebar(
                        store: store,
                        onCreatePlan: { isCreatingPlan = true },
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
        .frame(minWidth: 900, minHeight: 600)
        .sheet(isPresented: $isCreatingPlan) {
            CreatePlanSheet(
                onCancel: { isCreatingPlan = false },
                onCreate: { name, sources, destination in
                    createPlan(name: name, sources: sources, destination: destination)
                }
            )
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
    
    private func createPlan(name: String, sources: [URL], destination: URL) {
        do {
            let plan = try BackupPlan.create(
                name: name,
                sourceURLs: sources,
                destinationURL: destination
            )
            store.addPlan(plan)
            isCreatingPlan = false
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
