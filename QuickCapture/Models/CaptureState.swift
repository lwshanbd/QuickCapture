import Foundation

enum CaptureState {
    case idle
    case capturing       // Screen capture in progress
    case selecting       // User is dragging selection
    case selected        // Selection made, waiting for confirmation
    case confirmed       // Double-click confirmed, processing
}
