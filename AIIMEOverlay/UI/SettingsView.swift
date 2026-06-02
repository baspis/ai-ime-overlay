import SwiftUI

struct SettingsView: View {
    @ObservedObject var appState: AppState
    var onRefresh: (() -> Void)?

    @State private var apiKeyDraft = ""
    @State private var modelDraft = AppSettings.modelName
    @State private var statusMessage: String?
    @State private var isSaving = false

    var body: some View {
        Form {
            Section {
                Text("Romaji is sent to Google Gemini for conversion. Get a free API key at aistudio.google.com/apikey")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Gemini") {
                SecureField("API Key", text: $apiKeyDraft)
                    .textFieldStyle(.roundedBorder)

                if appState.hasAPIKey {
                    Text("A key is saved in Keychain. Enter a new key below to replace it.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                TextField("Model", text: $modelDraft)
                    .textFieldStyle(.roundedBorder)

                Text("Default: \(AppSettings.defaultModelName) (fastest/cheapest). Upgrade: \(AppSettings.recommendedUpgradeModelName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    Button("Save") { saveSettings() }
                        .disabled(isSaving)
                        .keyboardShortcut(.defaultAction)
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
                    granted: appState.hasAccessibility,
                    action: Permissions.openAccessibilitySettings
                )
                permissionRow(
                    title: "Input Monitoring",
                    granted: appState.hasInputMonitoring,
                    action: Permissions.openInputMonitoringSettings
                )

                Text("In System Settings, enable **AIIMEOverlay** (or the app at the path below).")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(Permissions.appPathForPrivacyList)
                    .font(.caption2)
                    .textSelection(.enabled)
                    .foregroundStyle(.secondary)

                HStack {
                    Button("Open Accessibility Settings") {
                        Permissions.openAccessibilitySettings()
                    }
                    Button("Open Input Monitoring Settings") {
                        Permissions.openInputMonitoringSettings()
                    }
                }

                Button("Refresh status") {
                    onRefresh?()
                    refreshDisplayedStatus()
                }

                Text("After granting permissions, click Refresh. If status stays off, quit AI IME from the menu bar and open the app again.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Usage") {
                Text("Double-tap Control to open the panel.")
                Text("Type romaji, press Control+Enter to convert, then Enter to insert.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(minWidth: 420, minHeight: 440)
        .onAppear {
            modelDraft = AppSettings.modelName
            refreshDisplayedStatus()
        }
    }

    @ViewBuilder
    private func permissionRow(title: String, granted: Bool, action: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
            Spacer()
            Image(systemName: granted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(granted ? .green : .orange)
                .help(granted ? "Granted" : "Not granted")
            Button("Open") { action() }
        }
    }

    private func refreshDisplayedStatus() {
        appState.refreshPermissionStatus()
        appState.refreshAPIKeyStatus()
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
