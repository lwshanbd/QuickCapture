import Foundation
import AppKit

enum ResizeHandle: CaseIterable {
    case topLeft, topRight, bottomLeft, bottomRight
    case topMiddle, bottomMiddle, leftMiddle, rightMiddle

    var isCorner: Bool {
        switch self {
        case .topLeft, .topRight, .bottomLeft, .bottomRight: return true
        default: return false
        }
    }
}

struct SelectionRect {
    var origin: CGPoint
    var end: CGPoint

    /// Create from a normalized CGRect (origin = topLeft in flipped coords).
    init(rect: CGRect) {
        self.origin = rect.origin
        self.end = CGPoint(x: rect.maxX, y: rect.maxY)
    }

    init(origin: CGPoint, end: CGPoint) {
        self.origin = origin
        self.end = end
    }

    var rect: CGRect {
        let x = min(origin.x, end.x)
        let y = min(origin.y, end.y)
        let w = abs(end.x - origin.x)
        let h = abs(end.y - origin.y)
        return CGRect(x: x, y: y, width: w, height: h)
    }

    var isEmpty: Bool {
        rect.width < 1 || rect.height < 1
    }

    /// Convert from flipped view coordinates to image pixel coordinates.
    /// In a flipped NSView, origin is top-left matching CGImage, so just scale.
    func imageRect(scaleFactor: CGFloat) -> CGRect {
        let r = rect
        return CGRect(
            x: r.origin.x * scaleFactor,
            y: r.origin.y * scaleFactor,
            width: r.width * scaleFactor,
            height: r.height * scaleFactor
        )
    }
}
