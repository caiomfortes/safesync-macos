import SwiftUI

struct PlanTypeChooserSheet: View {
    let onCancel: () -> Void
    let onChooseBackup: () -> Void
    let onChooseMirror: () -> Void
    
    var body: some View {
        VStack(spacing: DesignSpacing.xl) {
            VStack(spacing: DesignSpacing.sm) {
                Text("What kind of plan do you want to create?")
                    .font(DesignFont.title)
                    .foregroundStyle(Color.dsTextPrimary)
                Text("Choose the behavior that best fits your needs.")
                    .font(DesignFont.body)
                    .foregroundStyle(Color.dsTextSecondary)
            }
            .padding(.top, DesignSpacing.sm)
            .multilineTextAlignment(.center)
            
            HStack(spacing: DesignSpacing.lg) {
                planTypeCard(
                    icon: "externaldrive.badge.plus",
                    iconColor: Color.dsAccent,
                    title: "Backup",
                    description: "Copies new and updated files. Never removes anything from the destination.",
                    action: onChooseBackup
                )
                
                planTypeCard(
                    icon: "arrow.triangle.2.circlepath",
                    iconColor: Color.dsWarning,
                    title: "Sync",
                    description: "Mirrors source to destination. Orphan files are moved to Trash.",
                    action: onChooseMirror
                )
            }
            
            Button("Cancel", action: onCancel)
                .keyboardShortcut(.escape)
                .foregroundStyle(Color.dsTextSecondary)
        }
        .padding(DesignSpacing.xxl)
        .frame(width: 600)
        .background(Color.dsSurfaceSecondary)
    }
    
    private func planTypeCard(
        icon: String,
        iconColor: Color,
        title: String,
        description: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: DesignSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(iconColor)
                    .frame(height: 56)
                
                Text(title)
                    .font(DesignFont.title)
                    .foregroundStyle(Color.dsTextPrimary)
                
                Text(description)
                    .font(DesignFont.body)
                    .foregroundStyle(Color.dsTextSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(DesignSpacing.xl)
            .cardStyle()
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PlanTypeChooserSheet(
        onCancel: {},
        onChooseBackup: {},
        onChooseMirror: {}
    )
}
