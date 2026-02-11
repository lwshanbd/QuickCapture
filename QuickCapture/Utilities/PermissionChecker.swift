import AppKit

enum PermissionChecker {

    // MARK: - Screen Recording

    /// Check screen recording permission WITHOUT triggering any system dialog.
    static var isScreenRecordingGranted: Bool {
        CGPreflightScreenCaptureAccess()
    }

    /// Request screen recording permission (shows system dialog only if not yet granted).
    static func requestScreenRecording() {
        CGRequestScreenCaptureAccess()
    }

    static func openScreenRecordingSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }
}
