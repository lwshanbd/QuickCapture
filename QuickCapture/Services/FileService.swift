import AppKit

enum FileService {

    static func save(image: CGImage) {
        guard let data = ImageCropper.pngData(from: image) else {
            NSLog("QuickCapture: Failed to create PNG data for saving")
            return
        }

        let directory = SettingsManager.shared.saveDirectory
        let expandedPath = NSString(string: directory).expandingTildeInPath
        let dirURL = URL(fileURLWithPath: expandedPath)

        // Create directory if it doesn't exist
        do {
            try FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: true)
        } catch {
            NSLog("QuickCapture: Failed to create save directory: \(error)")
            return
        }

        let timestamp = DateFormatter.screenshotFormatter.string(from: Date())
        let filename = "\(Constants.screenshotFilePrefix)_\(timestamp).\(Constants.screenshotFileExtension)"
        let fileURL = dirURL.appendingPathComponent(filename)

        do {
            try data.write(to: fileURL)
            NSLog("QuickCapture: Screenshot saved to \(fileURL.path)")
        } catch {
            NSLog("QuickCapture: Failed to save screenshot: \(error)")
        }
    }

    static func saveWithPanel(image: CGImage) {
        guard let data = ImageCropper.pngData(from: image) else { return }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = "\(Constants.screenshotFilePrefix)_\(DateFormatter.screenshotFormatter.string(from: Date())).png"

        if panel.runModal() == .OK, let url = panel.url {
            do {
                try data.write(to: url)
                NSLog("QuickCapture: Screenshot saved to \(url.path)")
            } catch {
                NSLog("QuickCapture: Failed to save screenshot: \(error)")
            }
        }
    }
}

private extension DateFormatter {
    static let screenshotFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()
}
