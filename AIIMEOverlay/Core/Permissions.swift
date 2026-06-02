import AppKit
import ApplicationServices
import Foundation

enum Permissions {
    static var hasAccessibility: Bool {
        AXIsProcessTrusted()
    }

    static var hasInputMonitoring: Bool {
        if #available(macOS 10.15, *) {
            return CGPreflightListenEventAccess()
        }
        return true
    }

    static var isReady: Bool {
        hasAccessibility && hasInputMonitoring
    }

    /// Human-readable path shown in System Settings permission lists.
    static var appPathForPrivacyList: String {
        Bundle.main.bundleURL.path
    }

    @discardableResult
    static func requestAccessibility(prompt: Bool = true) -> Bool {
        if hasAccessibility { return true }
        if prompt {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(options)
        }
        return AXIsProcessTrusted()
    }

    @discardableResult
    static func requestInputMonitoring() -> Bool {
        if hasInputMonitoring { return true }
        if #available(macOS 10.15, *) {
            return CGRequestListenEventAccess()
        }
        return true
    }

    static func openAccessibilitySettings() {
        openPrivacySettings(anchor: "Privacy_Accessibility")
    }

    static func openInputMonitoringSettings() {
        openPrivacySettings(anchor: "Privacy_ListenEvent")
    }

    private static func openPrivacySettings(anchor: String) {
        // macOS 13+ System Settings
        let settingsURL = URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?\(anchor)")
        // Older System Preferences fallback
        let legacyURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(anchor)")

        if let settingsURL, NSWorkspace.shared.open(settingsURL) {
            return
        }
        if let legacyURL {
            NSWorkspace.shared.open(legacyURL)
        }
    }
}
