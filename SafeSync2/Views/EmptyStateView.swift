import SwiftUI

struct EmptyStateView: View {
    let onCreatePlan: () -> Void
    
    var body: some View {
        VStack(spacing: DesignSpacing.xl) {
            Image(systemName: "externaldrive.badge.plus")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(Color.dsAccent)
            
            VStack(spacing: DesignSpacing.sm) {
                Text("No backup plans")
                    .font(DesignFont.title)
                    .foregroundStyle(Color.dsTextPrimary)
                
                Text("Create your first plan to start making incremental backups.")
                    .font(DesignFont.body)
                    .foregroundStyle(Color.dsTextSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: onCreatePlan) {
                Label("Create first plan", systemImage: "plus")
                    .font(DesignFont.headline)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(Color.dsAccent)
            .padding(.top, DesignSpacing.sm)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(DesignSpacing.xxl)
        .background(Color.dsSurfaceSecondary)
    }
}

#Preview {
    EmptyStateView(onCreatePlan: {})
        .frame(width: 600, height: 500)
}
