import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var hotkeyService: HotkeyService?
    private var overlayController: OverlayWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        hotkeyService = HotkeyService { [weak self] in
            self?.triggerCapture()
        }
        hotkeyService?.start()
    }

    func triggerCapture() {
        guard overlayController == nil else { return }

        // Check permission silently — no dialog
        guard PermissionChecker.isScreenRecordingGranted else {
            // Only request once, then guide user
            PermissionChecker.requestScreenRecording()
            return
        }

        let images = ScreenCaptureService.captureAllScreens()
        guard !images.isEmpty else {
            NSLog("QuickCapture: No screen images captured.")
            return
        }

        let controller = OverlayWindowController(screenImages: images)
        controller.onDismiss = { [weak self] in
            self?.overlayController = nil
        }
        self.overlayController = controller
        controller.show()
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkeyService?.stop()
    }
}
