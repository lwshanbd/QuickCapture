import AppKit
import Carbon.HIToolbox

final class HotkeyService {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private let handler: () -> Void

    /// Static handler accessible from the C callback
    fileprivate static var sharedHandler: (() -> Void)?

    init(handler: @escaping () -> Void) {
        self.handler = handler
    }

    func start() {
        guard hotKeyRef == nil else { return }

        HotkeyService.sharedHandler = handler

        // Install Carbon event handler for hot key events
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let installStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            carbonHotKeyHandler,
            1,
            &eventType,
            nil,
            &eventHandlerRef
        )

        guard installStatus == noErr else {
            NSLog("QuickCapture: Failed to install event handler: \(installStatus)")
            return
        }

        // Register Cmd+Ctrl+A
        let hotKeyID = EventHotKeyID(
            signature: OSType(0x51435041), // "QCPA"
            id: 1
        )
        let modifiers = UInt32(cmdKey | controlKey)
        let keyCode = UInt32(kVK_ANSI_A)

        let regStatus = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if regStatus == noErr {
            NSLog("QuickCapture: Global hotkey registered (Cmd+Ctrl+A)")
        } else {
            NSLog("QuickCapture: Failed to register hotkey: \(regStatus)")
        }
    }

    func stop() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        if let ref = eventHandlerRef {
            RemoveEventHandler(ref)
            eventHandlerRef = nil
        }
        HotkeyService.sharedHandler = nil
    }

    deinit {
        stop()
    }
}

/// Top-level C-compatible function for the Carbon event handler callback.
private func carbonHotKeyHandler(
    nextHandler: EventHandlerCallRef?,
    event: EventRef?,
    userData: UnsafeMutableRawPointer?
) -> OSStatus {
    DispatchQueue.main.async {
        HotkeyService.sharedHandler?()
    }
    return noErr
}
