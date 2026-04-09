//
//  BackupPreviewSheet.swift
//  SafeSync2
//
//  Created by Caio Gabriel de Moura Fortes on 07/04/26.
//


import SwiftUI

struct BackupPreviewSheet: View {
    let data: BackupPreviewData
    let onCancel: () -> Void
    let onConfirm: () -> Void
    
    private let displayLimit = 100
    
    private var result: BackupPlanResult { data.result }
    private var planName: String { data.planName }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    summarySection
                    
                    if !result.newFiles.isEmpty {
                        fileListSection(
                            title: "Novos arquivos",
                            icon: "plus.circle.fill",
                            color: .green,
                            actions: result.newFiles
                        )
                    }
                    
                    if !result.updatedFiles.isEmpty {
                        fileListSection(
                            title: "Arquivos a atualizar",
                            icon: "arrow.triangle.2.circlepath.circle.fill",
                            color: .blue,
                            actions: result.updatedFiles
                        )
                    }
                    
                    if !result.errors.isEmpty {
                        errorsSection
                    }
                }
                .padding(20)
            }
            
            Divider()
            
            footer
        }
        .frame(width: 700, height: 600)
    }
    
    // MARK: - Subviews
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Pré-visualização do backup")
                .font(.title2)
                .bold()
            Text(planName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
    }
    
    private var summarySection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                summaryRow(
                    icon: "plus.circle.fill",
                    color: .green,
                    label: "Novos arquivos",
                    count: result.newFiles.count
                )
                summaryRow(
                    icon: "arrow.triangle.2.circlepath.circle.fill",
                    color: .blue,
                    label: "A atualizar",
                    count: result.updatedFiles.count
                )
                summaryRow(
                    icon: "equal.circle.fill",
                    color: .secondary,
                    label: "Inalterados",
                    count: result.unchangedCount
                )
                if let totalSize = data.totalSize {
                    summaryRow(
                        icon: "internaldrive.fill",
                        color: .purple,
                        label: "Tamanho total a copiar",
                        count: nil,
                        customValue: ByteFormatter.humanReadable(totalSize)
                    )
                }
                
                if !result.skippedSymlinks.isEmpty {
                    summaryRow(
                        icon: "link.circle.fill",
                        color: .orange,
                        label: "Links simbólicos ignorados",
                        count: result.skippedSymlinks.count
                    )
                }
                
                if !result.errors.isEmpty {
                    summaryRow(
                        icon: "exclamationmark.triangle.fill",
                        color: .red,
                        label: "Erros de leitura",
                        count: result.errors.count
                    )
                }
                
                if !data.fitsInDestination {
                    spaceWarningBanner(
                        icon: "xmark.octagon.fill",
                        color: .red,
                        title: "Espaço insuficiente no destino",
                        message: "Necessário: \(ByteFormatter.humanReadable(data.totalSize ?? 0)). Disponível: \(ByteFormatter.humanReadable(data.availableSpace ?? 0))."
                    )
                } else if data.isSpaceTight {
                    spaceWarningBanner(
                        icon: "exclamationmark.triangle.fill",
                        color: .orange,
                        title: "Espaço apertado no destino",
                        message: "Após esta operação, restará menos de 10% de espaço livre."
                    )
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            Label("Resumo", systemImage: "list.bullet.rectangle")
                .font(.headline)
        }
    }
    
    private func spaceWarningBanner(
        icon: String,
        color: Color,
        title: String,
        message: String
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.callout)
                    .bold()
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func summaryRow(
        icon: String,
        color: Color,
        label: String,
        count: Int? = nil,
        customValue: String? = nil
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 20)
            Text(label)
            Spacer()
            if let customValue {
                Text(customValue)
                    .font(.body.monospacedDigit())
                    .bold()
            } else if let count {
                Text("\(count)")
                    .font(.body.monospacedDigit())
                    .bold()
            }
        }
    }
    
    private func fileListSection(
        title: String,
        icon: String,
        color: Color,
        actions: [BackupAction]
    ) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(actions.prefix(displayLimit).enumerated()), id: \.offset) { _, action in
                    if let path = relativePath(from: action) {
                        HStack(spacing: 8) {
                            Image(systemName: "doc")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(path)
                                .font(.system(.caption, design: .monospaced))
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Spacer()
                        }
                        .padding(.vertical, 1)
                    }
                }
                
                if actions.count > displayLimit {
                    Text("... e mais \(actions.count - displayLimit) arquivo(s)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            Label("\(title) (\(actions.count))", systemImage: icon)
                .font(.headline)
                .foregroundStyle(color)
        }
    }
    
    private var errorsSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(result.errors.prefix(displayLimit), id: \.self) { error in
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .lineLimit(2)
                }
                if result.errors.count > displayLimit {
                    Text("... e mais \(result.errors.count - displayLimit) erro(s)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            Label("Erros de leitura", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.red)
        }
    }
    
    private var footer: some View {
        HStack {
            if !result.hasWork {
                Label("Nada para fazer — tudo já está atualizado", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.callout)
            }
            
            Spacer()
            
            Button("Cancelar", action: onCancel)
                .keyboardShortcut(.escape)
            
            Button("Confirmar e executar", action: onConfirm)
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
                .disabled(!result.hasWork || !data.fitsInDestination)
        }
        .padding(20)
    }
    
    // MARK: - Helpers
    
    private func relativePath(from action: BackupAction) -> String? {
        switch action {
        case .copyNew(_, _, let path): return path
        case .updateExisting(_, _, let path): return path
        case .skipUnchanged(let path): return path
        }
    }
}

#Preview {
    BackupPreviewSheet(
        data: BackupPreviewData(
            planName: "Meu Backup",
            result: BackupPlanResult(
                actions: [
                    .copyNew(source: URL(fileURLWithPath: "/a"), sourceRoot: URL(fileURLWithPath: "/"), relativePath: "documentos/relatorio.docx"),
                    .copyNew(source: URL(fileURLWithPath: "/b"), sourceRoot: URL(fileURLWithPath: "/"), relativePath: "fotos/praia.jpg"),
                    .updateExisting(source: URL(fileURLWithPath: "/c"), sourceRoot: URL(fileURLWithPath: "/"), relativePath: "planilhas/orcamento.xlsx")
                ],
                skippedSymlinks: [],
                errors: []
            ),
            sameVolume: false,
            totalSize: 4_500_000_000,
            availableSpace: 50_000_000_000
        ),
        onCancel: {},
        onConfirm: {}
    )
}
