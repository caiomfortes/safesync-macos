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
    
    private var iconName: String {
        plan.isMirrorMode ? "arrow.triangle.2.circlepath" : "externaldrive.fill"
    }
    
    private var iconColor: Color {
        plan.isMirrorMode ? .orange : .blue
    }
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .foregroundStyle(iconColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(plan.name)
                        .font(.body)
                        .lineLimit(1)
                    
                    if plan.isMirrorMode {
                        Text("SYNC")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(.orange.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                
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
