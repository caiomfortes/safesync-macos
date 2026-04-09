import SwiftUI

@main
struct SafeSync2App: App {
    @State private var store = PlanStore()
    @State private var historyStore = HistoryStore()
    @State private var coordinator: BackupCoordinator
    @AppStorage("appearanceMode") private var appearanceModeRaw: String = AppearanceMode.system.rawValue
    
    private var appearanceMode: AppearanceMode {
        AppearanceMode(rawValue: appearanceModeRaw) ?? .system
    }
    
    init() {
        let store = PlanStore()
        let historyStore = HistoryStore()
        self._store = State(initialValue: store)
        self._historyStore = State(initialValue: historyStore)
        self._coordinator = State(initialValue: BackupCoordinator(store: store, historyStore: historyStore))
    }
    
    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView(store: store, coordinator: coordinator, historyStore: historyStore)
                .preferredColorScheme(appearanceMode.colorScheme)
                .background {
                    PreviewWindowOpener(coordinator: coordinator)
                }
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                AboutMenuButton()
            }
            CommandGroup(replacing: .help) {
                HelpMenuButton()
            }
            
        }
        
        Settings {
            SettingsView()
        }
        
        Window("SafeSync Help", id: "help") {
            HelpView()
                .preferredColorScheme(appearanceMode.colorScheme)
        }
        .windowResizability(.contentSize)
        
        Window("Backup Preview", id: "preview") {
            StandalonePreviewWindow(coordinator: coordinator)
                .preferredColorScheme(appearanceMode.colorScheme)
        }
        .windowResizability(.contentSize)
        
        Window("About SafeSync", id: "about") {
            AboutView()
                .preferredColorScheme(appearanceMode.colorScheme)
        }
        .windowResizability(.contentSize)
        
        MenuBarExtra {
            MenuBarPopover(
                store: store,
                coordinator: coordinator,
                historyStore: historyStore
            )
            .preferredColorScheme(appearanceMode.colorScheme)
            .background {
                PreviewWindowOpener(coordinator: coordinator)
            }
        } label: {
            Image(systemName: hasActiveExecutions ? "externaldrive.fill.badge.timemachine" : "externaldrive.badge.timemachine")
        }
        .menuBarExtraStyle(.window)
    }
    
    private var hasActiveExecutions: Bool {
        coordinator.executions.contains { execution in
            switch execution.progress.phase {
            case .analyzing, .copying, .finishing, .queued:
                return true
            default:
                return false
            }
        }
    }
}

private struct HelpMenuButton: View {
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        Button("SafeSync Help") {
            openWindow(id: "help")
        }
        .keyboardShortcut("?", modifiers: [.command])
    }
}

private struct AboutMenuButton: View {
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        Button("About SafeSync") {
            openWindow(id: "about")
        }
    }
}
