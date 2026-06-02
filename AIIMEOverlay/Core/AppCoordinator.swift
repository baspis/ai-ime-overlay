import AppKit
import Foundation
import UserNotifications

@MainActor
final class AppCoordinator: ObservableObject {
    let appState = AppState()

    private let focusStore = FocusStore()
    private let hotkeyMonitor = HotkeyMonitor()
    private let panelController = ConversionPanelController()
    private let openAIClient = OpenAIClient()

    private var convertTask: Task<Void, Never>?

    func start() {
        panelController.onConvert = { [weak self] in self?.startConversion() }
        panelController.onCommit = { [weak self] in self?.commitConversion() }
        panelController.onDismiss = { [weak self] in self?.dismissPanel() }

        hotkeyMonitor.onDoubleControlTap = { [weak self] in
            self?.openPanel()
        }

        appState.refreshAPIKeyStatus()
        appState.refreshPermissionStatus()

        if !hotkeyMonitor.start() {
            appState.hotkeyMonitorRunning = false
            notify(
                title: "AI IME",
                body: "Could not start hotkey monitor. Grant Input Monitoring permission."
            )
        } else {
            appState.hotkeyMonitorRunning = true
        }
    }

    func stop() {
        convertTask?.cancel()
        hotkeyMonitor.stop()
        panelController.dismissPanel()
    }

    func openPanel() {
        guard Permissions.isReady else {
            Permissions.requestAccessibility(prompt: true)
            _ = Permissions.requestInputMonitoring()
            appState.refreshPermissionStatus()
            appState.showSettings = true
            notify(
                title: "AI IME",
                body: "Grant Accessibility and Input Monitoring permissions in Settings."
            )
            return
        }

        focusStore.capture()
        hotkeyMonitor.setPaused(true)
        panelController.present()
        appState.isPanelVisible = true
    }

    func dismissPanel(clearFocus: Bool = true) {
        convertTask?.cancel()
        convertTask = nil
        panelController.dismissPanel()
        hotkeyMonitor.setPaused(false)
        if clearFocus {
            focusStore.clear()
        }
        appState.isPanelVisible = false
    }

    func startConversion() {
        guard let apiKey = KeychainStore.readAPIKey() else {
            panelController.model.failConverting(message: OpenAIClientError.missingAPIKey.localizedDescription)
            appState.showSettings = true
            return
        }

        let romaji = panelController.model.romajiInput
        guard !romaji.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            panelController.model.failConverting(message: OpenAIClientError.emptyInput.localizedDescription)
            return
        }

        convertTask?.cancel()
        panelController.model.beginConverting()

        convertTask = Task { [weak self] in
            guard let self else { return }
            do {
                let result = try await openAIClient.convertRomaji(
                    romaji,
                    apiKey: apiKey,
                    model: AppSettings.modelName
                )
                guard !Task.isCancelled else { return }
                panelController.model.finishConverting(with: result)
            } catch {
                guard !Task.isCancelled else { return }
                let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                panelController.model.failConverting(message: message)
            }
        }
    }

    func commitConversion() {
        let text = panelController.model.previewText
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        dismissPanel(clearFocus: false)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self else { return }
            let result = TextInjector.insert(text, into: focusStore)
            self.focusStore.clear()

            switch result {
            case .insertedViaAccessibility, .insertedViaPasteboard:
                break
            case .copiedToPasteboardOnly:
                notify(
                    title: "AI IME",
                    body: "Could not insert automatically. Text is on the clipboard — paste with ⌘V."
                )
            case .failed:
                notify(
                    title: "AI IME",
                    body: "Could not insert text. Copy from the panel and paste manually."
                )
            }
        }
    }

    private func notify(title: String, body: String) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        center.add(request)
    }
}

@MainActor
final class AppState: ObservableObject {
    @Published var showSettings = false
    @Published var hasAPIKey = false
    @Published var hasAccessibility = false
    @Published var hasInputMonitoring = false
    @Published var hotkeyMonitorRunning = false
    @Published var isPanelVisible = false

    var permissionsReady: Bool {
        hasAccessibility && hasInputMonitoring
    }

    func refreshAPIKeyStatus() {
        hasAPIKey = KeychainStore.readAPIKey() != nil
    }

    func refreshPermissionStatus() {
        hasAccessibility = Permissions.hasAccessibility
        hasInputMonitoring = Permissions.hasInputMonitoring
    }
}
