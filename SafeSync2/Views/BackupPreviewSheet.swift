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
                VStack(alignment: .leading, spacing: DesignSpacing.lg) {
                    summarySection
                    
                    if !result.newFiles.isEmpty {
                        fileListSection(
                            title: "New files",
                            icon: "plus.circle.fill",
                            color: Color.dsSuccess,
                            actions: result.newFiles
                        )
                    }
                    
                    if !result.updatedFiles.isEmpty {
                        fileListSection(
                            title: "Files to update",
                            icon: "arrow.triangle.2.circlepath.circle.fill",
                            color: Color.dsAccent,
                            actions: result.updatedFiles
                        )
                    }
                    
                    if !result.orphans.isEmpty {
                        fileListSection(
                            title: "Files to remove (going to Trash)",
                            icon: "trash.circle.fill",
                            color: Color.dsDanger,
                            actions: result.orphans
                        )
                    }
                    
                    if !result.errors.isEmpty {
                        errorsSection
                    }
                }
                .padding(DesignSpacing.xl)
            }
            
            Divider()
            
            footer
        }
        .frame(width: 720, height: 620)
        .background(Color.dsSurfaceSecondary)
    }
    
    // MARK: - Subviews
    
    private var header: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.xs) {
            Text("Backup preview")
                .font(DesignFont.title)
                .foregroundStyle(Color.dsTextPrimary)
            Text(planName)
                .font(DesignFont.callout)
                .foregroundStyle(Color.dsTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSpacing.xl)
    }
    
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.md) {
            HStack(spacing: DesignSpacing.sm) {
                Image(systemName: "list.bullet.rectangle")
                    .foregroundStyle(Color.dsAccent)
                Text("Summary")
                    .font(DesignFont.headline)
                    .foregroundStyle(Color.dsTextPrimary)
            }
            
            VStack(spacing: DesignSpacing.sm) {
                summaryRow(
                    icon: "plus.circle.fill",
                    color: Color.dsSuccess,
                    label: "New files",
                    count: result.newFiles.count
                )
                summaryRow(
                    icon: "arrow.triangle.2.circlepath.circle.fill",
                    color: Color.dsAccent,
                    label: "To update",
                    count: result.updatedFiles.count
                )
                summaryRow(
                    icon: "equal.circle.fill",
                    color: Color.dsTextSecondary,
                    label: "Unchanged",
                    count: result.unchangedCount
                )
                
                if !result.orphans.isEmpty {
                    summaryRow(
                        icon: "trash.circle.fill",
                        color: Color.dsDanger,
                        label: "To move to Trash",
                        count: result.orphans.count
                    )
                }
                
                if let totalSize = data.totalSize {
                    summaryRow(
                        icon: "internaldrive.fill",
                        color: Color.dsAccent,
                        label: "Total size to copy",
                        count: nil,
                        customValue: ByteFormatter.humanReadable(totalSize)
                    )
                }
                
                if !result.skippedSymlinks.isEmpty {
                    summaryRow(
                        icon: "link.circle.fill",
                        color: Color.dsWarning,
                        label: "Symbolic links ignored",
                        count: result.skippedSymlinks.count
                    )
                }
                
                if !result.errors.isEmpty {
                    summaryRow(
                        icon: "exclamationmark.triangle.fill",
                        color: Color.dsDanger,
                        label: "Read errors",
                        count: result.errors.count
                    )
                }
            }
            
            if !data.fitsInDestination {
                spaceWarningBanner(
                    icon: "xmark.octagon.fill",
                    color: Color.dsDanger,
                    title: "Not enough space at destination",
                    message: "Required: \(ByteFormatter.humanReadable(data.totalSize ?? 0)). Available: \(ByteFormatter.humanReadable(data.availableSpace ?? 0))."
                )
            } else if data.isSpaceTight {
                spaceWarningBanner(
                    icon: "exclamationmark.triangle.fill",
                    color: Color.dsWarning,
                    title: "Tight space at destination",
                    message: "After this operation, less than 10% of free space will remain."
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
    
    private func summaryRow(
        icon: String,
        color: Color,
        label: String,
        count: Int? = nil,
        customValue: String? = nil
    ) -> some View {
        HStack(spacing: DesignSpacing.md) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 20)
            Text(label)
                .font(DesignFont.body)
                .foregroundStyle(Color.dsTextPrimary)
            Spacer()
            if let customValue {
                Text(customValue)
                    .font(DesignFont.body.monospacedDigit())
                    .foregroundStyle(Color.dsTextPrimary)
                    .bold()
            } else if let count {
                Text("\(count)")
                    .font(DesignFont.body.monospacedDigit())
                    .foregroundStyle(Color.dsTextPrimary)
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
        VStack(alignment: .leading, spacing: DesignSpacing.md) {
            HStack(spacing: DesignSpacing.sm) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text("\(title) (\(actions.count))")
                    .font(DesignFont.headline)
                    .foregroundStyle(Color.dsTextPrimary)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                ForEach(Array(actions.prefix(displayLimit).enumerated()), id: \.offset) { _, action in
                    if let path = relativePath(from: action) {
                        HStack(spacing: DesignSpacing.sm) {
                            Image(systemName: "doc")
                                .font(.caption)
                                .foregroundStyle(Color.dsTextSecondary)
                            Text(path)
                                .font(DesignFont.mono)
                                .foregroundStyle(Color.dsTextPrimary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Spacer()
                        }
                    }
                }
                
                if actions.count > displayLimit {
                    Text("... and \(actions.count - displayLimit) more")
                        .font(DesignFont.caption)
                        .foregroundStyle(Color.dsTextSecondary)
                        .padding(.top, DesignSpacing.xs)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
    
    private var errorsSection: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.md) {
            HStack(spacing: DesignSpacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.dsDanger)
                Text("Read errors")
                    .font(DesignFont.headline)
                    .foregroundStyle(Color.dsTextPrimary)
            }
            
            VStack(alignment: .leading, spacing: DesignSpacing.xs) {
                ForEach(result.errors.prefix(displayLimit), id: \.self) { error in
                    Text(error)
                        .font(DesignFont.caption)
                        .foregroundStyle(Color.dsDanger)
                        .lineLimit(2)
                }
                if result.errors.count > displayLimit {
                    Text("... and \(result.errors.count - displayLimit) more")
                        .font(DesignFont.caption)
                        .foregroundStyle(Color.dsTextSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
    
    private func spaceWarningBanner(
        icon: String,
        color: Color,
        title: String,
        message: String
    ) -> some View {
        HStack(alignment: .top, spacing: DesignSpacing.md) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignFont.body)
                    .foregroundStyle(Color.dsTextPrimary)
                    .bold()
                Text(message)
                    .font(DesignFont.caption)
                    .foregroundStyle(Color.dsTextSecondary)
            }
            Spacer()
        }
        .padding(DesignSpacing.md)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: DesignRadius.md))
    }
    
    private var footer: some View {
        HStack {
            if !result.hasWork {
                Label("Nothing to do — everything is up to date", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(Color.dsSuccess)
                    .font(DesignFont.body)
            }
            
            Spacer()
            
            Button("Cancel", action: onCancel)
                .keyboardShortcut(.escape)
                .foregroundStyle(Color.dsTextSecondary)
            
            Button("Confirm and run", action: onConfirm)
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
                .tint(Color.dsAccent)
                .disabled(!result.hasWork || !data.fitsInDestination)
        }
        .padding(DesignSpacing.xl)
    }
    
    private func relativePath(from action: BackupAction) -> String? {
        switch action {
        case .copyNew(_, _, let path): return path
        case .updateExisting(_, _, let path): return path
        case .skipUnchanged(let path): return path
        case .removeOrphan(let target, _): return target.path
        }
    }
}

#Preview {
    BackupPreviewSheet(
        data: BackupPreviewData(
            planName: "My Backup",
            result: BackupPlanResult(
                actions: [
                    .copyNew(source: URL(fileURLWithPath: "/a"), sourceRoot: URL(fileURLWithPath: "/"), relativePath: "documents/report.docx"),
                    .copyNew(source: URL(fileURLWithPath: "/b"), sourceRoot: URL(fileURLWithPath: "/"), relativePath: "photos/beach.jpg"),
                    .updateExisting(source: URL(fileURLWithPath: "/c"), sourceRoot: URL(fileURLWithPath: "/"), relativePath: "spreadsheets/budget.xlsx")
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
