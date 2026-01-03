import AppKit
import Carbon.HIToolbox

/// Manages global keyboard shortcuts for Silimon
class KeyboardShortcutService {
    static let shared = KeyboardShortcutService()

    private var eventMonitor: Any?
    private var hotKeyRef: EventHotKeyRef?
    private var togglePopoverHandler: (() -> Void)?

    private init() {}

    /// Register global hotkey to toggle popover
    /// Default: Command + Shift + S
    func registerToggleShortcut(handler: @escaping () -> Void) {
        self.togglePopoverHandler = handler

        // Use NSEvent global monitor for Command+Shift+S
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // Check for Command + Shift + S
            if event.modifierFlags.contains([.command, .shift]) &&
               event.keyCode == 1 {  // 1 = 'S' key
                self?.togglePopoverHandler?()
            }
        }
    }

    /// Register local monitor for when app is active
    func registerLocalShortcuts(handler: @escaping () -> Void) {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Command + Shift + S
            if event.modifierFlags.contains([.command, .shift]) &&
               event.keyCode == 1 {
                handler()
                return nil  // Consume the event
            }
            return event
        }
    }

    func unregisterAll() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    deinit {
        unregisterAll()
    }
}

/// Extension for displaying keyboard shortcut in UI
extension KeyboardShortcutService {
    static var toggleShortcutDisplay: String {
        "\u{2318}\u{21E7}S"  // ⌘⇧S
    }
}
