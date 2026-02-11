import Foundation
import Carbon.HIToolbox

enum Constants {
    static let appName = "QuickCapture"

    // Hotkey: Cmd+Ctrl+A
    static let hotkeyKeyCode: UInt16 = UInt16(kVK_ANSI_A)
    static let hotkeyModifiers: CGEventFlags = [.maskCommand, .maskControl]

    // Overlay
    static let overlayDimAlpha: CGFloat = 0.3
    static let selectionBorderWidth: CGFloat = 1.5
    static let selectionBorderColor = "selectionBorder" // Asset name or use system

    // Selection handles
    static let handleSize: CGFloat = 6
    static let handleHitRadius: CGFloat = 8
    static let handleBorderWidth: CGFloat = 1.5

    // File saving
    static let defaultSaveDirectory = "~/Pictures/QuickCapture"
    static let screenshotFilePrefix = "Screenshot"
    static let screenshotFileExtension = "png"

    // UserDefaults keys
    enum Keys {
        static let saveDirectory = "saveDirectory"
        static let launchAtLogin = "launchAtLogin"
        static let showNotification = "showNotification"
    }

    // Menu bar icon (SF Symbol)
    static let menuBarIcon = "camera.viewfinder"
}
