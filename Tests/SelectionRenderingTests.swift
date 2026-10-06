import AppKit
import SwiftUI

@main
struct SelectionRenderingTests {
    static func main() throws {
        _ = NSApplication.shared
        let screen = NSScreen.main!
        let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        // An isolated command-line executable uses its own preferences domain.
        UserDefaults.standard.setVolatileDomain(
            [Constants.Keys.saveDirectory: output.path], forName: UserDefaults.argumentDomain
        )
        let board = NSPasteboard.general
        let previousItems = board.pasteboardItems?.map { item -> NSPasteboardItem in
            let copy = NSPasteboardItem()
            for type in item.types {
                if let data = item.data(forType: type) { copy.setData(data, forType: type) }
            }
            return copy
        } ?? []
        defer {
            board.clearContents()
            board.writeObjects(previousItems)
        }

        let scale = screen.backingScaleFactor
        let context = CGContext(data: nil, width: Int(screen.frame.width * scale),
                                height: Int(screen.frame.height * scale), bitsPerComponent: 8,
                                bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.setFillColor(NSColor.blue.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: context.width, height: context.height))
        let image = context.makeImage()!
        var renderedFrames = 0

        for action in ["copy", "save", "double-click", "cancel"] {
            let controller = OverlayWindowController(screenImages: [(screen, image)])
            var dismissed = false
            controller.onDismiss = { dismissed = true }
            controller.show()
            let window = NSApp.windows.first { $0 is OverlayWindow && $0.isVisible }!
            // Exercise production event handlers without posting desktop input.
            window.orderOut(nil)
            let view = window.contentView as! SelectionView
            func event(_ type: NSEvent.EventType, _ point: CGPoint, clicks: Int = 1) -> NSEvent {
                NSEvent.mouseEvent(with: type, location: view.convert(point, to: nil),
                                   modifierFlags: [], timestamp: ProcessInfo.processInfo.systemUptime,
                                   windowNumber: window.windowNumber, context: nil,
                                   eventNumber: 0, clickCount: clicks, pressure: 1)!
            }
            func render() throws {
                let bounds = CGRect(x: 0, y: 0, width: 600, height: 500)
                let bitmap = view.bitmapImageRepForCachingDisplay(in: bounds)!
                view.cacheDisplay(in: bounds, to: bitmap)
                renderedFrames += 1
                if action == "copy" && renderedFrames == 200 {
                    try bitmap.representation(using: .png, properties: [:])!
                        .write(to: output.appendingPathComponent("selection.png"))
                    // White glyphs must be visible below the blue selection.
                    let sx = CGFloat(bitmap.pixelsWide) / bounds.width
                    let sy = CGFloat(bitmap.pixelsHigh) / bounds.height
                    var whitePixels = 0
                    for y in Int(308 * sy)..<Int(328 * sy) {
                        for x in Int(104 * sx)..<Int(200 * sx) {
                            let color = bitmap.colorAt(x: x, y: y)!.usingColorSpace(.deviceRGB)!
                            if min(color.redComponent, color.greenComponent, color.blueComponent) > 0.8 {
                                whitePixels += 1
                            }
                        }
                    }
                    precondition(whitePixels > 10, "Size indicator was not rendered")
                }
            }
            view.mouseDown(with: event(.leftMouseDown, CGPoint(x: 100, y: 100)))
            for i in 1...200 {
                view.mouseDragged(with: event(.leftMouseDragged, CGPoint(x: 100 + i, y: 300)))
                try autoreleasepool { try render() }
            }
            view.mouseUp(with: event(.leftMouseUp, CGPoint(x: 300, y: 300)))
            try render()
            let toolbar = (view.subviews.first { $0 is NSHostingView<SelectionToolbar> }
                           as! NSHostingView<SelectionToolbar>).rootView
            let changes = board.changeCount
            switch action {
            case "copy": toolbar.onCopy()
            case "save": toolbar.onSave()
            case "double-click":
                view.mouseDown(with: event(.leftMouseDown, CGPoint(x: 200, y: 200), clicks: 2))
            default: toolbar.onCancel()
            }
            precondition(dismissed && !window.isVisible, "Overlay did not dismiss")
            if action == "cancel" {
                precondition(board.changeCount == changes, "Cancel changed the clipboard")
            } else {
                let png = board.data(forType: .png)!
                let bitmap = NSBitmapImageRep(data: png)!
                precondition(bitmap.pixelsWide == Int(200 * scale) && bitmap.pixelsHigh == Int(200 * scale))
                precondition(board.data(forType: .tiff) != nil)
                if action == "save" {
                    let files = try FileManager.default.contentsOfDirectory(at: output, includingPropertiesForKeys: nil)
                    let saved = files.first { $0.lastPathComponent.hasPrefix("Screenshot_") }!
                    let savedData = try Data(contentsOf: saved)
                    precondition(savedData == png, "Saved image differs from clipboard")
                }
            }
            print("PASS: \(action), including selection rendering and dismissal")
        }
        print("PASS: \(renderedFrames) redraws; PNG/TIFF clipboard, PNG save, and visible size label")
    }
}
