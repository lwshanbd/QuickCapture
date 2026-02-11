import AppKit

enum ScreenCaptureService {

    /// Capture all screens using CGDisplayCreateImage (no ScreenCaptureKit, no permission dialogs).
    static func captureAllScreens() -> [(screen: NSScreen, image: CGImage)] {
        var results: [(screen: NSScreen, image: CGImage)] = []

        for screen in NSScreen.screens {
            guard let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else {
                continue
            }
            guard let image = CGDisplayCreateImage(displayID) else {
                continue
            }
            results.append((screen: screen, image: image))
        }

        return results
    }
}
