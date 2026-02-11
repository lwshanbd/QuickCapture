import AppKit

enum ImageCropper {

    /// Crop a CGImage using a SelectionRect from a given screen.
    static func crop(image: CGImage, selection: SelectionRect, screen: NSScreen) -> CGImage? {
        let scaleFactor = screen.backingScaleFactor
        let imageRect = selection.imageRect(scaleFactor: scaleFactor)

        // Clamp to image bounds
        let clampedRect = imageRect.intersection(
            CGRect(x: 0, y: 0, width: image.width, height: image.height)
        )

        guard !clampedRect.isEmpty else { return nil }
        return image.cropping(to: clampedRect)
    }

    /// Convert CGImage to PNG data
    static func pngData(from image: CGImage) -> Data? {
        let rep = NSBitmapImageRep(cgImage: image)
        return rep.representation(using: .png, properties: [:])
    }
}
