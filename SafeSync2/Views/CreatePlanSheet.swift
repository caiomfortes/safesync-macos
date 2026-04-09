import SwiftUI

struct CreatePlanSheet: View {
    let isMirrorMode: Bool
    let onCancel: () -> Void
    let onCreate: (String, [URL], URL, Bool) -> Void
    
    @State private var name: String = ""
    @State private var sourceURLs: [URL] = []
    @State private var destinationURL: URL? = nil
    
    private var canCreate: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
        && !sourceURLs.isEmpty
        && destinationURL != nil
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: isMirrorMode ? "arrow.triangle.2.circlepath" : "externaldrive.badge.plus")
                    .font(.title2)
                    .foregroundStyle(isMirrorMode ? .orange : .blue)
                
                Text(isMirrorMode ? "Novo plano de sincronização" : "Novo plano de backup")
                    .font(.title2)
                    .bold()
            }
            
            Form {
                TextField("Nome", text: $name, prompt: Text(isMirrorMode ? "Ex: Sincronizar Documentos" : "Ex: Backup de Documentos"))
                
                Section("Pastas fonte") {
                    if sourceURLs.isEmpty {
                        Text("Nenhuma pasta selecionada")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(sourceURLs, id: \.self) { url in
                            HStack {
                                Image(systemName: "folder")
                                Text(url.path)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                Spacer()
                                Button(role: .destructive) {
                                    sourceURLs.removeAll { $0 == url }
                                } label: {
                                    Image(systemName: "minus.circle")
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(.red)
                            }
                        }
                    }
                    
                    Button {
                        if let url = FolderPicker.pickerFolder(prompt: "Escolha uma pasta fonte") {
                            sourceURLs.append(url)
                        }
                    } label: {
                        Label("Adicionar pasta", systemImage: "plus")
                    }
                }
                
                Section("Destino") {
                    if let destinationURL {
                        HStack {
                            Image(systemName: "externaldrive")
                            Text(destinationURL.path)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    } else {
                        Text("Nenhum destino selecionado")
                            .foregroundStyle(.secondary)
                    }
                    
                    Button {
                        if let url = FolderPicker.pickerFolder(prompt: "Escolha o destino") {
                            destinationURL = url
                        }
                    } label: {
                        Label(destinationURL == nil ? "Selecionar destino" : "Alterar destino",
                              systemImage: "externaldrive.badge.plus")
                    }
                }
            }
            .formStyle(.grouped)
            
            HStack {
                Spacer()
                Button("Cancelar", action: onCancel)
                    .keyboardShortcut(.escape)
                
                Button("Criar") {
                    guard let destinationURL else { return }
                    onCreate(name, sourceURLs, destinationURL, isMirrorMode)
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
                .disabled(!canCreate)
            }
        }
        .padding()
        .frame(width: 560, height: 520)
    }
}

#Preview {
    CreatePlanSheet(
        isMirrorMode: false,
        onCancel: {},
        onCreate: { _, _, _, _ in }
    )
}
