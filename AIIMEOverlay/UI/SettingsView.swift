import SwiftUI

struct SettingsView: View {
    @ObservedObject var appState: AppState

    @State private var apiKeyDraft = ""
    @State private var modelDraft = AppSettings.modelName
    @State private var statusMessage: String?
    @State private var isSaving = false

    var body: some View {
        Form {
            Section {
                Text("Romaji you type is sent to OpenAI for conversion. Do not enter secrets.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("OpenAI") {
                SecureField("API Key", text: $apiKeyDraft)
                    .textFieldStyle(.roundedBorder)

                TextField("Model", text: $modelDraft)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    Button("Save") { saveSettings() }
                        .disabled(isSaving)
                    if appState.hasAPIKey {
                        Button("Remove Key", role: .destructive) { removeAPIKey() }
                    }
                }

                if let statusMessage {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Permissions") {
                permissionRow(
                    title: "Accessibility",
                    granted: Permissions.hasAccessibility,
                    action: Permissions.openAccessibilitySettings
                )
                permissionRow(
                    title: "Input Monitoring",
                    granted: Permissions.hasInputMonitoring,
                    action: Permissions.openInputMonitoringSettings
                )
                Button("Request Permissions") {
                    Permissions.requestAccessibility(prompt: true)
                    _ = Permissions.requestInputMonitoring()
                    appState.refreshPermissionStatus()
                }
            }

            Section("Usage") {
                Text("Double-tap Control to open the panel.")
                Text("Type romaji, press Control+Enter to convert, then Enter to insert.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 440, height: 420)
        .onAppear {
            apiKeyDraft = ""
            modelDraft = AppSettings.modelName
            appState.refreshPermissionStatus()
        }
    }

    @ViewBuilder
    private func permissionRow(title: String, granted: Bool, action: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
            Spacer()
            Image(systemName: granted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(granted ? .green : .orange)
            Button("Open Settings") { action() }
        }
    }

    private func saveSettings() {
        isSaving = true
        defer { isSaving = false }

        do {
            if !apiKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                try KeychainStore.saveAPIKey(apiKeyDraft)
                apiKeyDraft = ""
            }
            AppSettings.modelName = modelDraft
            appState.refreshAPIKeyStatus()
            statusMessage = "Settings saved."
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    private func removeAPIKey() {
        do {
            try KeychainStore.deleteAPIKey()
            apiKeyDraft = ""
            appState.refreshAPIKeyStatus()
            statusMessage = "API key removed."
        } catch {
            statusMessage = error.localizedDescription
        }
    }
}
