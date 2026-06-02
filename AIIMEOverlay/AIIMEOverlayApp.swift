import AppKit
import SwiftUI

@main
struct AIIMEOverlayApp: App {
    @StateObject private var coordinator = AppCoordinator()

    var body: some Scene {
        MenuBarExtra("AI IME", systemImage: "character.ja") {
            menuContent
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(appState: coordinator.appState)
        }
    }

    @ViewBuilder
    private var menuContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            if coordinator.appState.isPanelVisible {
                Text("Panel is open")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Double-tap Control")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !coordinator.appState.permissionsReady {
                Label("Permissions needed", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
            }

            if !coordinator.appState.hasAPIKey {
                Label("API key not set", systemImage: "key")
                    .foregroundStyle(.orange)
            }

            Divider()

            Button("Open Converter") {
                coordinator.openPanel()
            }
            .disabled(coordinator.appState.isPanelVisible)

            SettingsLink {
                Text("Settings…")
            } label: {
                Text("Settings…")
            }

            Divider()

            Button("Quit") {
                coordinator.stop()
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding(8)
        .onAppear {
            coordinator.start()
        }
        .onChange(of: coordinator.appState.showSettings) { _, show in
            guard show else { return }
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            coordinator.appState.showSettings = false
        }
    }
}
