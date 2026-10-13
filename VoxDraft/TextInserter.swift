import AppKit
#if !APP_STORE
import ApplicationServices
#endif
import Carbon

@MainActor
final class TextInserter {
    private var targetPID: pid_t?
#if !APP_STORE
    private var focusedElement: AXUIElement?
#endif
    private var lastExternalPID: pid_t?
    private var activationObserver: NSObjectProtocol?

    init() {
        if let app = NSWorkspace.shared.frontmostApplication,
           app.bundleIdentifier != Bundle.main.bundleIdentifier {
            lastExternalPID = app.processIdentifier
        }
        activationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  app.bundleIdentifier != Bundle.main.bundleIdentifier else { return }
            Task { @MainActor in self?.lastExternalPID = app.processIdentifier }
        }
    }

    deinit {
        if let activationObserver { NSWorkspace.shared.notificationCenter.removeObserver(activationObserver) }
    }

    func captureTarget() {
        if let app = NSWorkspace.shared.frontmostApplication,
           app.bundleIdentifier != Bundle.main.bundleIdentifier {
            targetPID = app.processIdentifier
            lastExternalPID = app.processIdentifier
        } else {
            targetPID = lastExternalPID
        }
#if !APP_STORE
        focusedElement = nil
        guard AXIsProcessTrusted(), let targetPID else { return }
        let app = AXUIElementCreateApplication(targetPID)
        var value: CFTypeRef?
        if AXUIElementCopyAttributeValue(app, kAXFocusedUIElementAttribute as CFString, &value) == .success,
           let value, CFGetTypeID(value) == AXUIElementGetTypeID() {
            focusedElement = (value as! AXUIElement)
        }
#endif
    }

    func requestAccessibility() {
#if APP_STORE
        _ = CGRequestPostEventAccess()
#else
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
#endif
    }

    func insert(_ text: String) async -> Bool {
        guard !text.isEmpty else { return false }
#if !APP_STORE
        guard AXIsProcessTrusted() else {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
            requestAccessibility()
            return false
        }

        if let focusedElement,
           AXUIElementSetAttributeValue(focusedElement, kAXSelectedTextAttribute as CFString, text as CFString) == .success {
            return true
        }
#endif

        // Some editors do not expose a writable selected-text accessibility attribute.
        // Paste through the target app in those cases. The clipboard keeps the text so
        // a failed paste can be retried manually.
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
#if APP_STORE
        // App Sandbox cannot use the assistive Accessibility APIs. The App Store
        // build requests only the separate Core Graphics event-posting consent.
        guard CGPreflightPostEventAccess() else {
            requestAccessibility()
            return false
        }
#endif
        guard let targetPID, let app = NSRunningApplication(processIdentifier: targetPID) else { return false }
        guard app.isActive || app.activate() else { return false }
        try? await Task.sleep(nanoseconds: 180_000_000)
        let source = CGEventSource(stateID: .combinedSessionState)
        guard let down = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false) else { return false }
        down.flags = .maskCommand
        up.flags = .maskCommand
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
        return true
    }
}
