import AppKit
import ApplicationServices
import Foundation

/// Captures the focused accessibility element before the overlay panel steals focus.
final class FocusStore {
    private var element: AXUIElement?
    private var pid: pid_t = 0

    func capture() {
        element = nil
        pid = 0

        let system = AXUIElementCreateSystemWide()
        var focusedValue: CFTypeRef?
        let status = AXUIElementCopyAttributeValue(
            system,
            kAXFocusedUIElementAttribute as CFString,
            &focusedValue
        )
        guard status == .success, let focusedValue else { return }

        let focused = focusedValue as! AXUIElement
        var processID: pid_t = 0
        guard AXUIElementGetPid(focused, &processID) == .success else { return }

        element = focused
        pid = processID
    }

    func clear() {
        element = nil
        pid = 0
    }

    var hasTarget: Bool {
        element != nil
    }

    /// Returns the stored element if it still belongs to a running process.
    func resolvedElement() -> AXUIElement? {
        guard let element else { return nil }
        var currentPID: pid_t = 0
        guard AXUIElementGetPid(element, &currentPID) == .success else {
            return nil
        }
        guard currentPID == pid, currentPID > 0 else {
            return nil
        }
        if NSRunningApplication(processIdentifier: currentPID) == nil {
            return nil
        }
        return element
    }

    func activateTargetApplication() -> Bool {
        guard pid > 0 else { return false }
        guard let app = NSRunningApplication(processIdentifier: pid) else { return false }
        return app.activate(options: [.activateIgnoringOtherApps])
    }
}
