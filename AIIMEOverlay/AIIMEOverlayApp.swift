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

            Button("Settings…") {
                coordinator.openSettings()
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
    }
}
