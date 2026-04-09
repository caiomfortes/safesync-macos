import SwiftUI

struct PlanDetailView: View {
    let plan: BackupPlan
    let store: PlanStore
    let coordinator: BackupCoordinator
    let historyStore: HistoryStore
    
    @State private var showFullHistory: Bool = false
    @State private var resolvedSources: [URL] = []
    @State private var resolvedDestination: URL? = nil
    @State private var resolutionError: String? = nil
    @State private var editedName: String = ""
    @State private var pendingConfirmExecutionID: UUID? = nil
    @State private var sheetForceClose: Bool = false
    @State private var showMirrorWarning: Bool = false
    
    private var historyEntries: [HistoryEntry] {
        historyStore.entries(forPlanID: plan.id)
    }

    private var visibleHistoryEntries: [HistoryEntry] {
        showFullHistory ? historyEntries : Array(historyEntries.prefix(5))
    }
    
    private var execution: BackupExecution? {
        coordinator.execution(forPlanID: plan.id)
    }
    
    private var isRunning: Bool {
        coordinator.isRunning(planID: plan.id)
    }
    
    private var accentColor: Color {
        plan.isMirrorMode ? Color.dsWarning : Color.dsAccent
    }
    
    private var isPreviewPresented: Binding<Bool> {
        Binding(
            get: {
                if sheetForceClose { return false }
                if case .waitingConfirmation = execution?.progress.phase {
                    return true
                }
                return false
            },
            set: { _ in }
        )
    }
    
    private var buttonLabel: String {
        guard let phase = execution?.progress.phase else { return String(localized: "Start backup") }
        switch phase {
        case .queued: return String(localized: "In queue...")
        case .analyzing: return String(localized: "Analyzing...")
        case .waitingConfirmation: return String(localized: "Waiting for confirmation")
        case .copying: return String(localized: "Copying...")
        case .finishing: return String(localized: "Finishing...")
        case .completed, .failed, .cancelled: return String(localized: "Start backup")
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSpacing.xl) {
                header
                
                if let resolutionError {
                    errorBanner(message: resolutionError)
                }
                
                sourcesSection
                destinationSection
                actionSection
                
                if let phase = execution?.progress.phase {
                    statusSection(phase: phase)
                }
                
                if !historyEntries.isEmpty {
                    historySection
                }
            }
            .padding(DesignSpacing.xl)
        }
        .background(Color.dsSurfaceSecondary)
        .navigationTitle(plan.name)
        .onAppear { loadPlan() }
        .onChange(of: plan.id) { _, _ in loadPlan() }
        .sheet(isPresented: isPreviewPresented) {
            if let previewData = execution?.previewData, let executionID = execution?.id {
                BackupPreviewSheet(
                    data: previewData,
                    onCancel: {
                        coordinator.cancelExecution(executionID: executionID)
                    },
                    onConfirm: {
                        if previewData.result.orphans.isEmpty {
                            coordinator.confirmExecution(executionID: executionID)
                        } else {
                            sheetForceClose = true
                            Task { @MainActor in
                                try? await Task.sleep(for: .milliseconds(100))
                                pendingConfirmExecutionID = executionID
                            }
                        }
                    }
                )
            }
        }
        .alert(
            "Confirm file removal?",
            isPresented: Binding(
                get: { pendingConfirmExecutionID != nil },
                set: { if !$0 { pendingConfirmExecutionID = nil } }
            ),
            presenting: pendingConfirmExecutionID
        ) { executionID in
            Button("Cancel", role: .cancel) {
                pendingConfirmExecutionID = nil
                sheetForceClose = false
            }
            Button("Continue", role: .destructive) {
                coordinator.confirmExecution(executionID: executionID)
                pendingConfirmExecutionID = nil
                sheetForceClose = false
            }
        } message: { _ in
            if let count = execution?.previewData?.result.orphans.count {
                Text("This operation will move \(count) file(s) or folder(s) from the destination to the Trash. You can recover them from the Trash if you change your mind. Continue?")
            }
        }
        .alert(
            "Switch to Sync mode?",
            isPresented: $showMirrorWarning
        ) {
            Button("Cancel", role: .cancel) {
                showMirrorWarning = false
            }
            Button("Confirm", role: .destructive) {
                togglePlanMode()
                showMirrorWarning = false
            }
        } message: {
            Text("In Sync mode, any file or folder at the destination that doesn't exist in the sources will be moved to the Trash on the next run. Are you sure you want to switch?")
        }
    }
    
    // MARK: - Subviews
    private var historySection: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.md) {
            HStack(spacing: DesignSpacing.sm) {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundStyle(Color.dsAccent)
                Text("Recent history")
                    .font(DesignFont.headline)
                    .foregroundStyle(Color.dsTextPrimary)
                
                Spacer()
                
                Text("\(historyEntries.count)")
                    .font(DesignFont.caption)
                    .foregroundStyle(Color.dsTextSecondary)
            }
            
            VStack(spacing: DesignSpacing.sm) {
                ForEach(visibleHistoryEntries) { entry in
                    HistoryRow(entry: entry)
                }
            }
            
            if historyEntries.count > 5 {
                Button {
                    showFullHistory.toggle()
                } label: {
                    Text(showFullHistory ? "Show less" : "Show all (\(historyEntries.count))")
                        .font(DesignFont.caption)
                }
                .buttonStyle(.borderless)
                .foregroundStyle(Color.dsAccent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.md) {
            HStack(spacing: DesignSpacing.md) {
                TextField("Plan name", text: $editedName)
                    .textFieldStyle(.plain)
                    .font(DesignFont.largeTitle)
                    .foregroundStyle(Color.dsTextPrimary)
                    .onSubmit { commitNameChange() }
                
                if plan.isMirrorMode {
                    Text("SYNC")
                        .tagStyle(color: Color.dsWarning, background: Color.dsWarningSoft)
                } else {
                    Text("BACKUP")
                        .tagStyle(color: Color.dsAccent, background: Color.dsAccentSoft)
                }
            }
            
            HStack(spacing: DesignSpacing.lg) {
                Label(
                    "Created \(plan.createdAt.formatted(.relative(presentation: .named)))",
                    systemImage: "calendar"
                )
                
                if let lastRun = plan.lastRunAt {
                    Label(
                        "Last backup \(lastRun.formatted(.relative(presentation: .named)))",
                        systemImage: "clock"
                    )
                } else {
                    Label("Never run", systemImage: "clock.badge.questionmark")
                }
            }
            .font(DesignFont.caption)
            .foregroundStyle(Color.dsTextSecondary)
            
            Button {
                if plan.isMirrorMode {
                    togglePlanMode()
                } else {
                    showMirrorWarning = true
                }
            } label: {
                Label(
                    plan.isMirrorMode ? "Switch to Backup mode" : "Switch to Sync mode",
                    systemImage: "arrow.triangle.swap"
                )
                .font(DesignFont.caption)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(Color.dsTextSecondary)
            .disabled(isRunning)
        }
    }
    
    private func errorBanner(message: String) -> some View {
        HStack(spacing: DesignSpacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.dsWarning)
            Text(message)
                .font(DesignFont.body)
                .foregroundStyle(Color.dsTextPrimary)
            Spacer()
        }
        .padding(DesignSpacing.md)
        .background(Color.dsWarningSoft)
        .clipShape(RoundedRectangle(cornerRadius: DesignRadius.md))
    }
    
    private var sourcesSection: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.md) {
            HStack(spacing: DesignSpacing.sm) {
                Image(systemName: "folder")
                    .foregroundStyle(Color.dsAccent)
                Text("Source folders")
                    .font(DesignFont.headline)
                    .foregroundStyle(Color.dsTextPrimary)
            }
            
            VStack(alignment: .leading, spacing: DesignSpacing.sm) {
                if resolvedSources.isEmpty {
                    Text("No source folders")
                        .font(DesignFont.body)
                        .foregroundStyle(Color.dsTextSecondary)
                } else {
                    ForEach(resolvedSources, id: \.self) { url in
                        HStack(spacing: DesignSpacing.sm) {
                            Image(systemName: "folder.fill")
                                .foregroundStyle(Color.dsAccent)
                            Text(url.path)
                                .font(DesignFont.mono)
                                .foregroundStyle(Color.dsTextPrimary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Spacer()
                            Button {
                                removeSource(url)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(Color.dsDanger)
                            }
                            .buttonStyle(.plain)
                            .disabled(isRunning)
                        }
                    }
                }
                
                Button {
                    addSource()
                } label: {
                    Label("Add source folder", systemImage: "plus")
                        .font(DesignFont.body)
                }
                .buttonStyle(.borderless)
                .foregroundStyle(Color.dsAccent)
                .disabled(isRunning)
                .padding(.top, DesignSpacing.xs)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
    
    private var destinationSection: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.md) {
            HStack(spacing: DesignSpacing.sm) {
                Image(systemName: "externaldrive")
                    .foregroundStyle(accentColor)
                Text("Destination")
                    .font(DesignFont.headline)
                    .foregroundStyle(Color.dsTextPrimary)
            }
            
            VStack(alignment: .leading, spacing: DesignSpacing.sm) {
                if let resolvedDestination {
                    HStack(spacing: DesignSpacing.sm) {
                        Image(systemName: "externaldrive.fill")
                            .foregroundStyle(accentColor)
                        Text(resolvedDestination.path)
                            .font(DesignFont.mono)
                            .foregroundStyle(Color.dsTextPrimary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                    }
                } else {
                    Text("No destination")
                        .font(DesignFont.body)
                        .foregroundStyle(Color.dsTextSecondary)
                }
                
                Button {
                    changeDestination()
                } label: {
                    Label("Change destination", systemImage: "arrow.triangle.2.circlepath")
                        .font(DesignFont.body)
                }
                .buttonStyle(.borderless)
                .foregroundStyle(accentColor)
                .disabled(isRunning)
                .padding(.top, DesignSpacing.xs)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
    
    private var actionSection: some View {
        HStack(spacing: DesignSpacing.md) {
            Button {
                coordinator.startAnalysis(for: plan)
            } label: {
                Label(buttonLabel, systemImage: "play.fill")
                    .font(DesignFont.headline)
                    .frame(minWidth: 160)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(accentColor)
            .disabled(isRunning || resolvedSources.isEmpty || resolvedDestination == nil)
            .keyboardShortcut("r", modifiers: [.command])
            
            if isRunning {
                ProgressView()
                    .controlSize(.small)
            }
            
            Spacer()
        }
    }
    
    private func statusSection(phase: BackupProgress.Phase) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            statusContent(phase: phase)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .cardStyle()
    }
    
    @ViewBuilder
    private func statusContent(phase: BackupProgress.Phase) -> some View {
        switch phase {
        case .queued:
            Text("In queue — starts when a slot is available")
                .font(DesignFont.body)
                .foregroundStyle(Color.dsTextSecondary)
        case .analyzing:
            Text("Analyzing files...")
                .font(DesignFont.body)
                .foregroundStyle(Color.dsTextPrimary)
        case .waitingConfirmation:
            Text("Waiting for confirmation")
                .font(DesignFont.body)
                .foregroundStyle(Color.dsTextSecondary)
        case .copying:
            if let exec = execution {
                Text("Copying \(exec.progress.filesProcessed) of \(exec.progress.filesTotal)")
                    .font(DesignFont.body)
                    .foregroundStyle(Color.dsTextPrimary)
            }
        case .finishing:
            Text("Finishing...")
                .font(DesignFont.body)
                .foregroundStyle(Color.dsTextPrimary)
        case .completed:
            Label("Completed", systemImage: "checkmark.circle.fill")
                .foregroundStyle(Color.dsSuccess)
                .font(DesignFont.body)
        case .failed(let message):
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.dsDanger)
                .font(DesignFont.body)
        case .cancelled:
            Label("Cancelled", systemImage: "xmark.circle")
                .foregroundStyle(Color.dsTextSecondary)
                .font(DesignFont.body)
        }
    }
    
    // MARK: - Actions
    
    private func loadPlan() {
        editedName = plan.name
        resolutionError = nil
        
        do {
            let resolved = try plan.resolve()
            resolvedSources = resolved.sourceURLs
            resolvedDestination = resolved.destinationURL
            
            if resolved.staleBookmarksDetected {
                refreshStaleBookmarks(resolved: resolved)
            }
        } catch {
            resolvedSources = []
            resolvedDestination = nil
            resolutionError = String(localized: "Could not load this plan's folders. You may need to reselect them.")
        }
    }
    
    private func refreshStaleBookmarks(resolved: BackupPlan.ResolvedPlan) {
        var activeURLs: [URL] = []
        
        for url in resolved.sourceURLs {
            if url.startAccessingSecurityScopedResource() {
                activeURLs.append(url)
            }
        }
        if resolved.destinationURL.startAccessingSecurityScopedResource() {
            activeURLs.append(resolved.destinationURL)
        }
        
        defer {
            for url in activeURLs {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            let freshPlan = try BackupPlan.create(
                name: plan.name,
                sourceURLs: resolved.sourceURLs,
                destinationURL: resolved.destinationURL
            )
            let updated = plan.withUpdatedBookmarks(
                sourceBookmarks: freshPlan.sourceBookmarks,
                destinationBookmark: freshPlan.destinationBookmark
            )
            store.updatePlan(updated)
        } catch {
            resolutionError = String(localized: "Stale bookmarks. Reselect folders to continue.")
        }
    }
    
    private func commitNameChange() {
        let trimmed = editedName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, trimmed != plan.name else {
            editedName = plan.name
            return
        }
        let updated = plan.withUpdatedName(trimmed)
        store.updatePlan(updated)
    }
    
    private func addSource() {
        guard let url = FolderPicker.pickerFolder(prompt: "Choose source folder") else { return }
        let newSources = resolvedSources + [url]
        rebuildPlan(withSources: newSources, destination: resolvedDestination)
    }
    
    private func removeSource(_ url: URL) {
        let newSources = resolvedSources.filter { $0 != url }
        rebuildPlan(withSources: newSources, destination: resolvedDestination)
    }
    
    private func changeDestination() {
        guard let url = FolderPicker.pickerFolder(prompt: "Choose destination") else { return }
        rebuildPlan(withSources: resolvedSources, destination: url)
    }
    
    private func rebuildPlan(withSources sources: [URL], destination: URL?) {
        guard let destination else { return }
        
        var activeURLs: [URL] = []
        for url in sources {
            if url.startAccessingSecurityScopedResource() {
                activeURLs.append(url)
            }
        }
        if destination.startAccessingSecurityScopedResource() {
            activeURLs.append(destination)
        }
        
        defer {
            for url in activeURLs {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            let freshPlan = try BackupPlan.create(
                name: plan.name,
                sourceURLs: sources,
                destinationURL: destination
            )
            let updated = plan.withUpdatedBookmarks(
                sourceBookmarks: freshPlan.sourceBookmarks,
                destinationBookmark: freshPlan.destinationBookmark
            )
            store.updatePlan(updated)
            resolvedSources = sources
            resolvedDestination = destination
        } catch {
            resolutionError = String(localized: "Update error: \(error.localizedDescription)")
        }
    }
    
    private func togglePlanMode() {
        let updated = plan.withUpdatedMirrorMode(!plan.isMirrorMode)
        store.updatePlan(updated)
    }
}

private struct HistoryRow: View {
    let entry: HistoryEntry
    
    private var iconName: String {
        switch entry.outcome {
        case .completed: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }
    
    private var iconColor: Color {
        switch entry.outcome {
        case .completed: return Color.dsSuccess
        case .failed: return Color.dsDanger
        case .cancelled: return Color.dsTextSecondary
        }
    }
    
    private var summaryText: String {
        switch entry.outcome {
        case .completed:
            var parts: [String] = []
            if entry.copiedCount > 0 { parts.append("\(entry.copiedCount) new") }
            if entry.updatedCount > 0 { parts.append("\(entry.updatedCount) updated") }
            if entry.orphansRemovedCount > 0 { parts.append("\(entry.orphansRemovedCount) removed") }
            return parts.isEmpty ? String(localized: "Nothing to do") : parts.joined(separator: ", ")
        case .failed:
            return entry.firstFailureMessage ?? String(localized: "Failed")
        case .cancelled:
            return String(localized: "Cancelled by user")
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: DesignSpacing.md) {
            Image(systemName: iconName)
                .foregroundStyle(iconColor)
                .frame(width: 18)
                .padding(.top, 1)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: DesignSpacing.sm) {
                    Text(entry.startedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(DesignFont.body)
                        .foregroundStyle(Color.dsTextPrimary)
                    
                    if entry.wasMirrorMode {
                        Text("SYNC")
                            .tagStyle(color: Color.dsWarning, background: Color.dsWarningSoft)
                    }
                    
                    Spacer()
                    
                    Text(TimeFormatter.humanReadable(seconds: entry.duration))
                        .font(DesignFont.caption.monospacedDigit())
                        .foregroundStyle(Color.dsTextSecondary)
                }
                
                Text(summaryText)
                    .font(DesignFont.caption)
                    .foregroundStyle(Color.dsTextSecondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, DesignSpacing.xs)
    }
}


#Preview {
    let store = PlanStore()
    let historyStore = HistoryStore()
    let coordinator = BackupCoordinator(store: store, historyStore: historyStore)
    let plan = BackupPlan(
        name: "Sample Plan",
        sourceBookmarks: [],
        destinationBookmark: Data()
    )
    return PlanDetailView(plan: plan, store: store, coordinator: coordinator, historyStore: historyStore)
        .frame(width: 700, height: 600)
}
