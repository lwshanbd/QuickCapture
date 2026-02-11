import AppKit

enum ClipboardService {

    static func copy(image: CGImage) {
        guard let pngData = ImageCropper.pngData(from: image) else {
            NSLog("QuickCapture: Failed to create PNG data for clipboard")
            return
        }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setData(pngData, forType: .png)

        // Also set as TIFF for broader compatibility
        let nsImage = NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
        if let tiffData = nsImage.tiffRepresentation {
            pasteboard.setData(tiffData, forType: .tiff)
        }

        NSLog("QuickCapture: Image copied to clipboard (\(image.width)x\(image.height))")
    }
}
