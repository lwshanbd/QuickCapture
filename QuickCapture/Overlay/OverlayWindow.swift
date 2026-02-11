import AppKit

final class OverlayWindow: NSWindow {

    convenience init(screen: NSScreen) {
        self.init(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        self.setFrame(screen.frame, display: false)
        self.level = .statusBar + 1
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.ignoresMouseEvents = false
        self.acceptsMouseMovedEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }

    // Borderless windows return false by default — must override
    // so the window can become key, receive proper clickCount tracking,
    // and isKeyWindow returns true for active screen detection.
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
