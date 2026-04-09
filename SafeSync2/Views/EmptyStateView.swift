
import SwiftUI

struct EmptyStateView: View {
    let onCreatePlan: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "externaldrive.badge.plus")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            Text("Nenhum plano de backup")
                .font(.title2)
                .bold()
            
            Text("Crie seu primeiro plano para começar\na fazer backups incrementais.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            
            Button(action: onCreatePlan) {
                Label("Criar primeiro plano", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    EmptyStateView(onCreatePlan: {})
        .frame(width: 600, height: 500)
}
