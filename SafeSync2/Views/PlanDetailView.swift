import SwiftUI

struct PlanDetailView: View {
    let plan: BackupPlan
    let store: PlanStore
    let coordinator: BackupCoordinator
    
    @State private var resolvedSources: [URL] = []
    @State private var resolvedDestination: URL? = nil
    @State private var resolutionError: String? = nil
    @State private var editedName: String = ""
    
    private var execution: BackupExecution? {
        coordinator.execution(forPlanID: plan.id)
    }
    
    private var isRunning: Bool {
        coordinator.isRunning(planID: plan.id)
    }
    
    private var isPreviewPresented: Binding<Bool> {
        Binding(
            get: {
                if case .waitingConfirmation = execution?.progress.phase {
                    return true
                }
                return false
            },
            set: { newValue in
                if !newValue, let id = execution?.id {
                    coordinator.cancelExecution(executionID: id)
                }
            }
        )
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
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
            }
            .padding(24)
        }
        .navigationTitle(plan.name)
        .onAppear {
            loadPlan()
        }
        .onChange(of: plan.id) { _, _ in
            loadPlan()
        }
        .sheet(isPresented: isPreviewPresented) {
            if let previewData = execution?.previewData, let executionID = execution?.id {
                BackupPreviewSheet(
                    data: previewData,
                    onCancel: {
                        coordinator.cancelExecution(executionID: executionID)
                    },
                    onConfirm: {
                        coordinator.confirmExecution(executionID: executionID)
                    }
                )
            }
        }
    }
    
    // MARK: - Subviews
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Nome do plano", text: $editedName)
                .textFieldStyle(.plain)
                .font(.largeTitle)
                .bold()
                .onSubmit {
                    commitNameChange()
                }
            
            HStack(spacing: 12) {
                Label("Criado \(plan.createdAt.formatted(.relative(presentation: .named)))",
                      systemImage: "calendar")
                
                if let lastRun = plan.lastRunAt {
                    Label("Último backup \(lastRun.formatted(.relative(presentation: .named)))",
                          systemImage: "clock")
                } else {
                    Label("Nunca executado", systemImage: "clock.badge.questionmark")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
    
    private func errorBanner(message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.callout)
            Spacer()
        }
        .padding(12)
        .background(.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var sourcesSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                if resolvedSources.isEmpty {
                    Text("Nenhuma pasta fonte")
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                } else {
                    ForEach(resolvedSources, id: \.self) { url in
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundStyle(.tint)
                            Text(url.path)
                                .font(.system(.body, design: .monospaced))
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Spacer()
                            Button {
                                removeSource(url)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red.opacity(0.8))
                            }
                            .buttonStyle(.plain)
                            .disabled(isRunning)
                        }
                        .padding(.vertical, 2)
                    }
                }
                
                Button {
                    addSource()
                } label: {
                    Label("Adicionar pasta fonte", systemImage: "plus")
                }
                .buttonStyle(.borderless)
                .padding(.top, 4)
                .disabled(isRunning)
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            Label("Pastas fonte", systemImage: "folder")
                .font(.headline)
        }
    }
    
    private var destinationSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                if let resolvedDestination {
                    HStack {
                        Image(systemName: "externaldrive.fill")
                            .foregroundStyle(.tint)
                        Text(resolvedDestination.path)
                            .font(.system(.body, design: .monospaced))
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                    }
                    .padding(.vertical, 2)
                } else {
                    Text("Nenhum destino")
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                }
                
                Button {
                    changeDestination()
                } label: {
                    Label("Alterar destino", systemImage: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.borderless)
                .padding(.top, 4)
                .disabled(isRunning)
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            Label("Destino", systemImage: "externaldrive")
                .font(.headline)
        }
    }
    
    private var actionSection: some View {
        HStack {
            Button {
                coordinator.startAnalysis(for: plan)
            } label: {
                Label(isRunning ? "Em execução..." : "Iniciar backup",
                      systemImage: "play.fill")
                    .frame(minWidth: 140)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isRunning || resolvedSources.isEmpty || resolvedDestination == nil)
            
            if isRunning {
                ProgressView()
                    .controlSize(.small)
                    .padding(.leading, 4)
            }
            
            Spacer()
        }
    }
    
    private func statusSection(phase: BackupProgress.Phase) -> some View {
        GroupBox {
            statusContent(phase: phase)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
        }
    }
    
    @ViewBuilder
    private func statusContent(phase: BackupProgress.Phase) -> some View {
        switch phase {
        case .queued:
            Text("Aguardando na fila...")
                .font(.callout)
                .foregroundStyle(.secondary)
        case .analyzing:
            Text("Analisando arquivos...")
                .font(.callout)
        case .waitingConfirmation:
            Text("Aguardando confirmação")
                .font(.callout)
                .foregroundStyle(.secondary)
        case .copying:
            if let exec = execution {
                Text("Copiando \(exec.progress.filesProcessed) de \(exec.progress.filesTotal)")
                    .font(.callout)
            }
        case .finishing:
            Text("Finalizando...")
                .font(.callout)
        case .completed:
            Label("✅ Concluído", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.callout)
        case .failed(let message):
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
                .font(.callout)
        case .cancelled:
            Label("Cancelado", systemImage: "xmark.circle")
                .foregroundStyle(.secondary)
                .font(.callout)
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
            resolutionError = "Não foi possível carregar as pastas deste plano. Pode ser necessário reselecioná-las."
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
            resolutionError = "Bookmarks desatualizados. Reselecione as pastas para continuar."
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
        guard let url = FolderPicker.pickerFolder(prompt: "Escolha uma pasta fonte") else { return }
        let newSources = resolvedSources + [url]
        rebuildPlan(withSources: newSources, destination: resolvedDestination)
    }
    
    private func removeSource(_ url: URL) {
        let newSources = resolvedSources.filter { $0 != url }
        rebuildPlan(withSources: newSources, destination: resolvedDestination)
    }
    
    private func changeDestination() {
        guard let url = FolderPicker.pickerFolder(prompt: "Escolha o destino") else { return }
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
            resolutionError = "Erro ao atualizar: \(error.localizedDescription)"
        }
    }
}

#Preview {
    let store = PlanStore()
    let coordinator = BackupCoordinator(store: store)
    let plan = BackupPlan(
        name: "Plano de Exemplo",
        sourceBookmarks: [],
        destinationBookmark: Data()
    )
    return PlanDetailView(plan: plan, store: store, coordinator: coordinator)
        .frame(width: 700, height: 600)
}
