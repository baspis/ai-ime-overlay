import AppKit
import SwiftUI

@MainActor
final class ConversionPanelController: NSWindowController {
    let model = ConversionPanelModel()

    var onConvert: (() -> Void)?
    var onCommit: (() -> Void)?
    var onDismiss: (() -> Void)?

    private var localMonitor: Any?
    private var globalMonitor: Any?

    init() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 280),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.title = "AI IME"
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.center()

        super.init(window: panel)

        let view = ConversionPanelView(
            model: model,
            onConvert: { [weak self] in self?.onConvert?() },
            onCommit: { [weak self] in self?.onCommit?() },
            onDismiss: { [weak self] in self?.onDismiss?() }
        )
        panel.contentView = NSHostingView(rootView: view)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func present() {
        guard let panel = window as? NSPanel else { return }
        model.reset()
        panel.center()
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        installMonitors()
    }

    func dismissPanel() {
        removeMonitors()
        window?.orderOut(nil)
        model.reset()
    }

    private func installMonitors() {
        removeMonitors()

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            self?.handleKeyEvent(event) ?? event
        }

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            _ = self?.handleKeyEvent(event)
        }
    }

    private func removeMonitors() {
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
    }

    @discardableResult
    private func handleKeyEvent(_ event: NSEvent) -> NSEvent? {
        guard window?.isVisible == true else { return event }

        if event.type == .keyDown {
            if event.keyCode == 53 { // Esc
                onDismiss?()
                return nil
            }

            let controlDown = event.modifierFlags.contains(.control)

            if event.keyCode == 36, controlDown { // Ctrl+Enter
                onConvert?()
                return nil
            }

            if event.keyCode == 36, !controlDown, !event.modifierFlags.contains(.shift) {
                if model.canCommit {
                    onCommit?()
                    return nil
                }
            }
        }

        return event
    }
}
