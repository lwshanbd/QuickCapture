import AppKit

protocol SelectionViewDelegate: AnyObject {
    func selectionViewDidSelect(_ rect: SelectionRect)
    func selectionViewDidConfirm(_ rect: SelectionRect)
    func selectionViewDidCancel()
    func selectionViewDidStartNewSelection()
}

final class SelectionView: NSView {
    weak var delegate: SelectionViewDelegate?

    private let backgroundImage: CGImage
    private var selection: SelectionRect?
    private var hasSelection = false
    private var lastClickInSelectionTime: TimeInterval = 0

    private enum DragMode {
        case none
        case newSelection
        case moveSelection(startPoint: CGPoint, originalRect: CGRect)
        case resizeHandle(handle: ResizeHandle, originalRect: CGRect)
    }
    private var dragMode: DragMode = .none

    override var isFlipped: Bool { true }

    init(frame: NSRect, backgroundImage: CGImage) {
        self.backgroundImage = backgroundImage
        super.init(frame: frame)
        addTrackingArea(NSTrackingArea(
            rect: .zero,
            options: [.mouseMoved, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        ))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        // Draw the full screenshot as background
        context.saveGState()
        context.translateBy(x: 0, y: bounds.height)
        context.scaleBy(x: 1, y: -1)
        context.draw(backgroundImage, in: CGRect(origin: .zero, size: bounds.size))
        context.restoreGState()

        // Draw dim overlay on the entire view
        NSColor.black.withAlphaComponent(Constants.overlayDimAlpha).setFill()
        bounds.fill()

        // If there's a selection, clear the dim overlay inside and draw border
        if let selection = selection, !selection.isEmpty {
            let selRect = selection.rect

            // Clear the dim overlay inside the selection (reveal the bright screenshot)
            context.saveGState()
            context.setBlendMode(.clear)
            context.fill(selRect)
            context.restoreGState()

            // Redraw the screenshot in the selection area
            context.saveGState()
            context.clip(to: selRect)
            context.translateBy(x: 0, y: bounds.height)
            context.scaleBy(x: 1, y: -1)
            context.draw(backgroundImage, in: CGRect(origin: .zero, size: bounds.size))
            context.restoreGState()

            // Draw selection border
            let borderPath = NSBezierPath(rect: selRect)
            NSColor.systemBlue.setStroke()
            borderPath.lineWidth = Constants.selectionBorderWidth
            borderPath.stroke()

            // Draw size indicator
            drawSizeIndicator(for: selRect, in: context)

            // Draw resize handles when selection is finalized
            if hasSelection {
                drawHandles(for: selRect)
            }
        }
    }

    private func drawSizeIndicator(for rect: CGRect, in context: CGContext) {
        let screen = window?.screen ?? NSScreen.main!
        let scale = screen.backingScaleFactor
        let w = Int(rect.width * scale)
        let h = Int(rect.height * scale)
        let text = "\(w) × \(h)" as NSString

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .medium),
            .foregroundColor: NSColor.white
        ]
        let textSize = text.size(withAttributes: attributes)
        let padding: CGFloat = 6

        let bgRect = CGRect(
            x: rect.minX,
            y: rect.maxY + 4,
            width: textSize.width + padding * 2,
            height: textSize.height + padding * 2
        )

        if bgRect.maxY <= bounds.height {
            let bgPath = NSBezierPath(roundedRect: bgRect, xRadius: 4, yRadius: 4)
            NSColor.black.withAlphaComponent(0.7).setFill()
            bgPath.fill()

            let textPoint = CGPoint(x: bgRect.minX + padding, y: bgRect.minY + padding)
            text.draw(at: textPoint, withAttributes: attributes)
        }
    }

    private func drawHandles(for rect: CGRect) {
        let size = Constants.handleSize
        for handle in ResizeHandle.allCases {
            let center = handleCenter(handle, in: rect)
            let handleRect = CGRect(
                x: center.x - size / 2,
                y: center.y - size / 2,
                width: size,
                height: size
            )
            let path = NSBezierPath(rect: handleRect)
            NSColor.white.setFill()
            path.fill()
            NSColor.systemBlue.setStroke()
            path.lineWidth = Constants.handleBorderWidth
            path.stroke()
        }
    }

    // MARK: - Handle Geometry

    private func handleCenter(_ handle: ResizeHandle, in rect: CGRect) -> CGPoint {
        switch handle {
        case .topLeft:      return CGPoint(x: rect.minX, y: rect.minY)
        case .topRight:     return CGPoint(x: rect.maxX, y: rect.minY)
        case .bottomLeft:   return CGPoint(x: rect.minX, y: rect.maxY)
        case .bottomRight:  return CGPoint(x: rect.maxX, y: rect.maxY)
        case .topMiddle:    return CGPoint(x: rect.midX, y: rect.minY)
        case .bottomMiddle: return CGPoint(x: rect.midX, y: rect.maxY)
        case .leftMiddle:   return CGPoint(x: rect.minX, y: rect.midY)
        case .rightMiddle:  return CGPoint(x: rect.maxX, y: rect.midY)
        }
    }

    private func hitTestHandle(at point: CGPoint) -> ResizeHandle? {
        guard let sel = selection else { return nil }
        let rect = sel.rect
        let radius = Constants.handleHitRadius

        // Test corners first (higher priority)
        for handle in ResizeHandle.allCases where handle.isCorner {
            let center = handleCenter(handle, in: rect)
            if hypot(point.x - center.x, point.y - center.y) <= radius {
                return handle
            }
        }
        // Then edges
        for handle in ResizeHandle.allCases where !handle.isCorner {
            let center = handleCenter(handle, in: rect)
            if hypot(point.x - center.x, point.y - center.y) <= radius {
                return handle
            }
        }
        return nil
    }

    // MARK: - Resize / Move Helpers

    private func resizedRect(_ rect: CGRect, handle: ResizeHandle, to point: CGPoint) -> CGRect {
        var minX = rect.minX, maxX = rect.maxX, minY = rect.minY, maxY = rect.maxY

        switch handle {
        case .topLeft:      minX = point.x; minY = point.y
        case .topRight:     maxX = point.x; minY = point.y
        case .bottomLeft:   minX = point.x; maxY = point.y
        case .bottomRight:  maxX = point.x; maxY = point.y
        case .topMiddle:    minY = point.y
        case .bottomMiddle: maxY = point.y
        case .leftMiddle:   minX = point.x
        case .rightMiddle:  maxX = point.x
        }

        // Normalize so min <= max (allows dragging past opposite edge)
        let x1 = min(minX, maxX), x2 = max(minX, maxX)
        let y1 = min(minY, maxY), y2 = max(minY, maxY)
        return CGRect(x: x1, y: y1, width: x2 - x1, height: y2 - y1)
    }

    private func clampRect(_ rect: CGRect, to bounds: CGRect) -> CGRect {
        var r = rect
        if r.minX < bounds.minX { r.origin.x = bounds.minX }
        if r.minY < bounds.minY { r.origin.y = bounds.minY }
        if r.maxX > bounds.maxX { r.origin.x = bounds.maxX - r.width }
        if r.maxY > bounds.maxY { r.origin.y = bounds.maxY - r.height }
        return r
    }

    // MARK: - Mouse Events

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)

        if hasSelection, let sel = selection {
            // Double-click inside selection → confirm
            if sel.rect.contains(point) {
                let isDoubleClick = event.clickCount >= 2
                    || (event.timestamp - lastClickInSelectionTime) < NSEvent.doubleClickInterval
                if isDoubleClick {
                    delegate?.selectionViewDidConfirm(sel)
                    return
                }
                lastClickInSelectionTime = event.timestamp
            }

            // Hit test handles
            if let handle = hitTestHandle(at: point) {
                dragMode = .resizeHandle(handle: handle, originalRect: sel.rect)
                return
            }

            // Click inside selection → move
            if sel.rect.contains(point) {
                dragMode = .moveSelection(startPoint: point, originalRect: sel.rect)
                NSCursor.closedHand.set()
                return
            }
        }

        // Click outside (or no selection) → new selection
        lastClickInSelectionTime = 0
        dragMode = .newSelection
        hasSelection = false
        selection = SelectionRect(origin: point, end: point)
        delegate?.selectionViewDidStartNewSelection()
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)

        switch dragMode {
        case .none:
            return

        case .newSelection:
            selection?.end = point

        case .moveSelection(let startPoint, let originalRect):
            let dx = point.x - startPoint.x
            let dy = point.y - startPoint.y
            var moved = originalRect.offsetBy(dx: dx, dy: dy)
            moved = clampRect(moved, to: bounds)
            selection = SelectionRect(rect: moved)

        case .resizeHandle(let handle, let originalRect):
            let newRect = resizedRect(originalRect, handle: handle, to: point)
            selection = SelectionRect(rect: newRect)
        }

        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard case .none = dragMode else {
            // For move/resize, update drag origin to current state for next drag
            let wasNewSelection: Bool
            if case .newSelection = dragMode { wasNewSelection = true } else { wasNewSelection = false }

            if wasNewSelection {
                let point = convert(event.locationInWindow, from: nil)
                selection?.end = point
            }

            dragMode = .none

            if let sel = selection, !sel.isEmpty {
                hasSelection = true
                delegate?.selectionViewDidSelect(sel)
            } else if case .none = dragMode {
                // tiny selection from new drag
                selection = nil
                hasSelection = false
            }

            needsDisplay = true
            updateCursor(at: convert(event.locationInWindow, from: nil))
            return
        }
    }

    override func mouseMoved(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        updateCursor(at: point)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            delegate?.selectionViewDidCancel()
        }
    }

    override var acceptsFirstResponder: Bool { true }

    // MARK: - Cursor Management

    private func updateCursor(at point: CGPoint) {
        guard hasSelection, let sel = selection else {
            NSCursor.crosshair.set()
            return
        }

        if let handle = hitTestHandle(at: point) {
            cursorForHandle(handle).set()
        } else if sel.rect.contains(point) {
            NSCursor.openHand.set()
        } else {
            NSCursor.crosshair.set()
        }
    }

    private func cursorForHandle(_ handle: ResizeHandle) -> NSCursor {
        switch handle {
        case .topLeft, .bottomRight:
            return NSCursor(image: resizeCursorImage(angle: -45), hotSpot: NSPoint(x: 8, y: 8))
        case .topRight, .bottomLeft:
            return NSCursor(image: resizeCursorImage(angle: 45), hotSpot: NSPoint(x: 8, y: 8))
        case .topMiddle, .bottomMiddle:
            return .resizeUpDown
        case .leftMiddle, .rightMiddle:
            return .resizeLeftRight
        }
    }

    /// Generate a diagonal resize arrow cursor image.
    private func resizeCursorImage(angle: CGFloat) -> NSImage {
        let size = NSSize(width: 16, height: 16)
        let image = NSImage(size: size, flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            ctx.translateBy(x: 8, y: 8)
            ctx.rotate(by: angle * .pi / 180)
            ctx.setStrokeColor(NSColor.black.cgColor)
            ctx.setLineWidth(1.5)
            // Vertical line with arrowheads
            ctx.move(to: CGPoint(x: 0, y: -6))
            ctx.addLine(to: CGPoint(x: 0, y: 6))
            // Top arrowhead
            ctx.move(to: CGPoint(x: -3, y: 3))
            ctx.addLine(to: CGPoint(x: 0, y: 6))
            ctx.addLine(to: CGPoint(x: 3, y: 3))
            // Bottom arrowhead
            ctx.move(to: CGPoint(x: -3, y: -3))
            ctx.addLine(to: CGPoint(x: 0, y: -6))
            ctx.addLine(to: CGPoint(x: 3, y: -3))
            ctx.strokePath()
            return true
        }
        return image
    }

    override func resetCursorRects() {
        // Handled dynamically in mouseMoved / updateCursor
        addCursorRect(bounds, cursor: .crosshair)
    }
}
