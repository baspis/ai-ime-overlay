import AppKit
import ApplicationServices
import Foundation

enum TextInjector {
    enum InsertResult {
        case insertedViaAccessibility
        case insertedViaPasteboard
        case copiedToPasteboardOnly
        case failed
    }

    static func insert(_ text: String, into focusStore: FocusStore) -> InsertResult {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .failed }

        _ = focusStore.activateTargetApplication()

        if let element = focusStore.resolvedElement(),
           insertViaAccessibility(trimmed, into: element) {
            return .insertedViaAccessibility
        }

        if insertViaPasteboard(trimmed, focusStore: focusStore) {
            return .insertedViaPasteboard
        }

        copyToPasteboard(trimmed)
        return .copiedToPasteboardOnly
    }

    // MARK: - Accessibility

    private static func insertViaAccessibility(_ text: String, into element: AXUIElement) -> Bool {
        if setSelectedText(text, on: element) { return true }
        if appendToValue(text, on: element) { return true }
        return false
    }

    private static func setSelectedText(_ text: String, on element: AXUIElement) -> Bool {
        let status = AXUIElementSetAttributeValue(
            element,
            kAXSelectedTextAttribute as CFString,
            text as CFTypeRef
        )
        return status == .success
    }

    private static func appendToValue(_ text: String, on element: AXUIElement) -> Bool {
        var currentValue: CFTypeRef?
        let readStatus = AXUIElementCopyAttributeValue(
            element,
            kAXValueAttribute as CFString,
            &currentValue
        )
        guard readStatus == .success else { return false }

        let existing: String
        if let string = currentValue as? String {
            existing = string
        } else if let attributed = currentValue as? NSAttributedString {
            existing = attributed.string
        } else {
            existing = ""
        }

        let combined = existing + text
        let writeStatus = AXUIElementSetAttributeValue(
            element,
            kAXValueAttribute as CFString,
            combined as CFTypeRef
        )
        return writeStatus == .success
    }

    // MARK: - Pasteboard fallback

    private static func insertViaPasteboard(_ text: String, focusStore: FocusStore) -> Bool {
        let pasteboard = NSPasteboard.general
        let previous = pasteboard.string(forType: .string)
        copyToPasteboard(text)

        // Brief delay so the target app can accept focus after activation.
        usleep(80_000)

        guard simulateCommandV() else {
            restorePasteboard(pasteboard, previous: previous)
            return false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            restorePasteboard(pasteboard, previous: previous)
        }
        return true
    }

    private static func copyToPasteboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    private static func restorePasteboard(_ pasteboard: NSPasteboard, previous: String?) {
        pasteboard.clearContents()
        if let previous {
            pasteboard.setString(previous, forType: .string)
        }
    }

    private static func simulateCommandV() -> Bool {
        let source = CGEventSource(stateID: .combinedSessionState)

        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        keyDown?.flags = .maskCommand
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        keyUp?.flags = .maskCommand

        guard let keyDown, let keyUp else { return false }
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
        return true
    }
}
