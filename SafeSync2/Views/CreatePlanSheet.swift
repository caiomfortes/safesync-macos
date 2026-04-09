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
    
    private var accentColor: Color {
        isMirrorMode ? Color.dsWarning : Color.dsAccent
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.lg) {
            HStack(spacing: DesignSpacing.md) {
                Image(systemName: isMirrorMode ? "arrow.triangle.2.circlepath" : "externaldrive.badge.plus")
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(accentColor)
                
                Text(isMirrorMode ? "New sync plan" : "New backup plan")
                    .font(DesignFont.title)
                    .foregroundStyle(Color.dsTextPrimary)
            }
            
            Form {
                TextField(
                    "Name",
                    text: $name,
                    prompt: Text(isMirrorMode ? "e.g. Sync Documents" : "e.g. Documents Backup")
                )
                .font(DesignFont.body)
                
                Section {
                    if sourceURLs.isEmpty {
                        Text("No folders selected")
                            .font(DesignFont.body)
                            .foregroundStyle(Color.dsTextSecondary)
                    } else {
                        ForEach(sourceURLs, id: \.self) { url in
                            HStack(spacing: DesignSpacing.sm) {
                                Image(systemName: "folder")
                                    .foregroundStyle(Color.dsAccent)
                                Text(url.path)
                                    .font(DesignFont.callout)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                Spacer()
                                Button {
                                    sourceURLs.removeAll { $0 == url }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(Color.dsDanger)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    Button {
                        if let url = FolderPicker.pickerFolder(prompt: "Choose source folder") {
                            sourceURLs.append(url)
                        }
                    } label: {
                        Label("Add folder", systemImage: "plus")
                            .font(DesignFont.body)
                    }
                } header: {
                    Text("Source folders")
                        .font(DesignFont.headline)
                        .foregroundStyle(Color.dsTextPrimary)
                }
                
                Section {
                    if let destinationURL {
                        HStack(spacing: DesignSpacing.sm) {
                            Image(systemName: "externaldrive")
                                .foregroundStyle(accentColor)
                            Text(destinationURL.path)
                                .font(DesignFont.callout)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    } else {
                        Text("No destination selected")
                            .font(DesignFont.body)
                            .foregroundStyle(Color.dsTextSecondary)
                    }
                    
                    Button {
                        if let url = FolderPicker.pickerFolder(prompt: "Choose destination") {
                            destinationURL = url
                        }
                    } label: {
                        Label(
                            destinationURL == nil ? "Select destination" : "Change destination",
                            systemImage: "externaldrive.badge.plus"
                        )
                        .font(DesignFont.body)
                    }
                } header: {
                    Text("Destination")
                        .font(DesignFont.headline)
                        .foregroundStyle(Color.dsTextPrimary)
                }
            }
            .formStyle(.grouped)
            
            HStack(spacing: DesignSpacing.md) {
                Spacer()
                
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.escape)
                    .foregroundStyle(Color.dsTextSecondary)
                
                Button("Create") {
                    guard let destinationURL else { return }
                    onCreate(name, sourceURLs, destinationURL, isMirrorMode)
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
                .tint(accentColor)
                .disabled(!canCreate)
            }
        }
        .padding(DesignSpacing.xl)
        .frame(width: 580, height: 540)
        .background(Color.dsSurfaceSecondary)
    }
}

#Preview {
    CreatePlanSheet(
        isMirrorMode: false,
        onCancel: {},
        onCreate: { _, _, _, _ in }
    )
}
