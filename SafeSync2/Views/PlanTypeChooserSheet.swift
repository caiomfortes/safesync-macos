//
//  PlanTypeChooserSheet.swift
//  SafeSync2
//
//  Created by Caio Gabriel de Moura Fortes on 08/04/26.
//


import SwiftUI

struct PlanTypeChooserSheet: View {
    let onCancel: () -> Void
    let onChooseBackup: () -> Void
    let onChooseMirror: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 6) {
                Text("Que tipo de plano você quer criar?")
                    .font(.title2)
                    .bold()
                Text("Escolha o comportamento que melhor se adequa ao seu uso.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 8)
            
            HStack(spacing: 16) {
                planTypeCard(
                    icon: "externaldrive.badge.plus",
                    iconColor: .blue,
                    title: "Backup",
                    description: "Copia arquivos novos e atualizados. Nunca remove nada do destino.",
                    action: onChooseBackup
                )
                
                planTypeCard(
                    icon: "arrow.triangle.2.circlepath",
                    iconColor: .orange,
                    title: "Sincronização",
                    description: "Espelha a origem no destino. Arquivos órfãos são movidos para o Lixo.",
                    action: onChooseMirror
                )
            }
            
            Button("Cancelar", action: onCancel)
                .keyboardShortcut(.escape)
        }
        .padding(28)
        .frame(width: 600)
    }
    
    private func planTypeCard(
        icon: String,
        iconColor: Color,
        title: String,
        description: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 42))
                    .foregroundStyle(iconColor)
                    .frame(height: 56)
                
                Text(title)
                    .font(.title3)
                    .bold()
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(.background.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(.separator, lineWidth: 1)
            }
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