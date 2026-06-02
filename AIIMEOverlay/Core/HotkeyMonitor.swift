import AppKit
import CoreGraphics
import Foundation

/// Detects a double-tap on the Control modifier key via CGEventTap.
final class HotkeyMonitor {
    var onDoubleControlTap: (() -> Void)?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isPaused = false

    private var tapCount = 0
    private var lastPressTime: TimeInterval = 0
    private var controlWasDown = false

    private let tapTimeWindow: TimeInterval

    init(tapTimeWindow: TimeInterval = NSEvent.doubleClickInterval) {
        self.tapTimeWindow = tapTimeWindow
    }

    func start() -> Bool {
        guard eventTap == nil else { return true }

        let mask = CGEventMask(1 << CGEventType.flagsChanged.rawValue)
        let callback: CGEventTapCallBack = { proxy, type, event, userInfo in
            guard let userInfo else {
                return Unmanaged.passUnretained(event)
            }
            let monitor = Unmanaged<HotkeyMonitor>.fromOpaque(userInfo).takeUnretainedValue()
            return monitor.handleEvent(proxy: proxy, type: type, event: event)
        }

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            return false
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        if let runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        eventTap = nil
        self.runLoopSource = nil
        resetTapState()
    }

    func setPaused(_ paused: Bool) {
        isPaused = paused
        if paused {
            resetTapState()
        }
    }

    private func handleEvent(
        proxy: CGEventTapProxy,
        type: CGEventType,
        event: CGEvent
    ) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        guard type == .flagsChanged, !isPaused else {
            return Unmanaged.passUnretained(event)
        }

        guard let nsEvent = NSEvent(cgEvent: event), nsEvent.type == .flagsChanged else {
            return Unmanaged.passUnretained(event)
        }

        let flags = nsEvent.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let controlDown = flags.contains(.control)

        if controlDown && !controlWasDown {
            registerControlPress(at: nsEvent.timestamp)
        }

        controlWasDown = controlDown
        return Unmanaged.passUnretained(event)
    }

    private func registerControlPress(at timestamp: TimeInterval) {
        let interval = timestamp - lastPressTime
        if tapCount == 1, interval <= tapTimeWindow {
            tapCount = 0
            lastPressTime = 0
            DispatchQueue.main.async { [weak self] in
                self?.onDoubleControlTap?()
            }
            return
        }

        tapCount = 1
        lastPressTime = timestamp
    }

    private func resetTapState() {
        tapCount = 0
        lastPressTime = 0
        controlWasDown = false
    }
}
