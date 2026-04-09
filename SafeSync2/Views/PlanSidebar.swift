
import SwiftUI

struct PlanSidebar: View {
    let store: PlanStore
    let onCreatePlan: () -> Void
    let onDeletePlan: (BackupPlan) -> Void
    
    var body: some View {
        List(selection: Binding(
            get: { store.selectedPlanID },
            set: { store.selectPlan(id: $0) }
        )) {
            ForEach(store.plans) { plan in
                PlanRow(plan: plan)
                    .tag(plan.id)
                    .contextMenu {
                        Button(role: .destructive) {
                            onDeletePlan(plan)
                        } label: {
                            Label("Apagar", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.sidebar)
        .toolbar {
            ToolbarItem {
                Button(action: onCreatePlan) {
                    Label("Novo plano", systemImage: "plus")
                }
            }
        }
        .navigationTitle("SafeSync")
    }
}

private struct PlanRow: View {
    let plan: BackupPlan
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "externaldrive.fill")
                .foregroundStyle(.tint)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(plan.name)
                    .font(.body)
                    .lineLimit(1)
                
                if let lastRun = plan.lastRunAt {
                    Text("Último: \(lastRun.formatted(.relative(presentation: .named)))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Nunca executado")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    PlanSidebar(
        store: PlanStore(),
        onCreatePlan: {},
        onDeletePlan: { _ in }
    )
    .frame(width: 250, height: 400)
}
