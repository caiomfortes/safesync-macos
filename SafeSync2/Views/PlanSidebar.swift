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
                    .listRowSeparator(.hidden)
                    .contextMenu {
                        Button(role: .destructive) {
                            onDeletePlan(plan)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.sidebar)
        .toolbar {
            ToolbarItem {
                Button(action: onCreatePlan) {
                    Label("New plan", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: [.command])
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
        plan.isMirrorMode ? Color.dsWarning : Color.dsAccent
    }
    
    var body: some View {
        HStack(spacing: DesignSpacing.md) {
            Image(systemName: iconName)
                .font(.system(size: 16))
                .foregroundStyle(iconColor)
                .frame(width: 22)
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: DesignSpacing.xs) {
                    Text(plan.name)
                        .font(DesignFont.headline)
                        .foregroundStyle(Color.dsTextPrimary)
                        .lineLimit(1)
                    
                    if plan.isMirrorMode {
                        Text("SYNC")
                            .tagStyle(color: Color.dsWarning, background: Color.dsWarningSoft)
                    }
                }
                
                if let lastRun = plan.lastRunAt {
                    Text(lastRun.formatted(.relative(presentation: .named)))
                        .font(DesignFont.caption)
                        .foregroundStyle(Color.dsTextSecondary)
                } else {
                    Text("Never run")
                        .font(DesignFont.caption)
                        .foregroundStyle(Color.dsTextSecondary)
                }
            }
        }
        .padding(.vertical, DesignSpacing.xs)
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
