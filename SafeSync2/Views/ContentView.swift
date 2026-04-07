//
//  ContentView.swift
//  SafeSync2
//
//  Created by Caio Gabriel de Moura Fortes on 07/04/26.
//

import SwiftUI


struct ContentView: View {
    @State private var sourceURLs: [URL] = []
    @State private var destinationURL: URL? = nil
    @State private var statusMessage: String = "Pronto"
    
    
    var body: some View{
        VStack(alignment: .leading, spacing: 16){
            Text("SafeSync")
                .font(.largeTitle)
                .bold()
            
            GroupBox("Pastas Fonte"){
                VStack(){
                    if sourceURLs.isEmpty {
                        Text("Nenhuma pasta adicionada")
                            .foregroundStyle(.secondary)
                    } else{
                        ForEach(sourceURLs, id: \.self) { url in
                            Text(url.path)
                                .font(.system(.body, design: .monospaced))
                        }
                    }
                    
                    Button("+ Adicionar Pasta Fonte"){
                        addSource()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
            }
            
            
            GroupBox("Destino"){
                VStack(){
                    if let destinationURL {
                        Text(destinationURL.path)
                            .font(.system(.body, design: .monospaced))
                    } else{
                        Text("Nenhum destino selecionado")
                            .foregroundStyle(.secondary)
                    }
                    Button("Selecionar Destino"){
                        pickDeastination()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
            }
            
            Button("Iniciar Backup"){
                Task {
                    await runBackup()
                }
            }
            
            
            Text(statusMessage)
                .foregroundStyle(.secondary)
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 600, minHeight: 300)
    }
    
    
    private func addSource(){
        if let url = FolderPicker.pickerFolder(prompt: "Escolha uma pasta fonte"){
            sourceURLs.append(url)
        }
    }
    
    private func pickDeastination(){
        if let url = FolderPicker.pickerFolder(prompt: "Escolha um destino"){
            destinationURL = url
        }
    }
    
    
    
    private func runBackup() async {
        guard let destinationURL else { return }
        
        // Ativa acesso às pastas (se viessem de bookmarks, seria necessário)
        statusMessage = "Analisando..."
        
        let engine = BackupEngine()
        let result = await engine.analyze(sources: sourceURLs, destination: destinationURL)
        
        statusMessage = "Copiando \(result.actions.count) itens..."
        
        let report = await engine.execute(result: result, destination: destinationURL)
        
        statusMessage = "✅ Concluído. \(report.copied) novos, \(report.updated) atualizados, \(report.failures.count) falhas."
    }
    
}





#Preview {
    ContentView()
}
