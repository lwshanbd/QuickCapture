import AppKit
import SwiftUI

final class OverlayWindowController: NSObject, SelectionViewDelegate {
    private var windows: [OverlayWindow] = []
    private var selectionViews: [SelectionView] = []
    private var screenImages: [(screen: NSScreen, image: CGImage)]
    private var toolbarView: NSView?
    private var currentSelection: SelectionRect?
    private var activeIndex: Int?

    var onDismiss: (() -> Void)?

    init(screenImages: [(screen: NSScreen, image: CGImage)]) {
        self.screenImages = screenImages
        super.init()
    }

    func show() {
        NSCursor.crosshair.push()

        for (screen, image) in screenImages {
            let window = OverlayWindow(screen: screen)
            let selectionView = SelectionView(
                frame: CGRect(origin: .zero, size: screen.frame.size),
                backgroundImage: image
            )
            selectionView.delegate = self

            window.contentView = selectionView
            window.makeKeyAndOrderFront(nil)
            window.makeFirstResponder(selectionView)

            windows.append(window)
            selectionViews.append(selectionView)
        }

        // Activate the app so it can receive key events
        NSApp.activate(ignoringOtherApps: true)
    }

    func dismiss() {
        hideToolbar()
        NSCursor.pop()

        for window in windows {
            window.orderOut(nil)
        }
        windows.removeAll()
        selectionViews.removeAll()
        screenImages = []
        currentSelection = nil
        activeIndex = nil
        onDismiss?()
    }

    // MARK: - SelectionViewDelegate

    func selectionViewDidSelect(_ rect: SelectionRect) {
        currentSelection = rect

        // Prefer the screen under mouse to avoid mismatches on multi-display setups.
        activeIndex = resolvedActiveIndex()

        showToolbar(for: rect)
    }

    func selectionViewDidConfirm(_ rect: SelectionRect) {
        cropAndCopy(selection: rect)
        dismiss()
    }

    func selectionViewDidCancel() {
        dismiss()
    }

    func selectionViewDidStartNewSelection() {
        hideToolbar()
    }

    // MARK: - Toolbar

    private func showToolbar(for selection: SelectionRect) {
        hideToolbar()

        guard let index = activeIndex ?? resolvedActiveIndex(),
              selectionViews.indices.contains(index) else {
            return
        }
        let targetView = selectionViews[index]

        let toolbar = SelectionToolbar(
            onSave: { [weak self] in self?.saveSelection() },
            onCopy: { [weak self] in self?.copySelection() },
            onCancel: { [weak self] in self?.dismiss() }
        )

        let hostingView = NSHostingView(rootView: toolbar)
        hostingView.frame.size = hostingView.fittingSize

        let selRect = selection.rect
        let bounds = targetView.bounds
        let margin: CGFloat = 8
        let width = hostingView.frame.width
        let height = hostingView.frame.height

        var x = selRect.minX
        x = min(max(x, bounds.minX + margin), bounds.maxX - width - margin)

        // In flipped coordinates: larger y means lower on screen.
        let belowY = selRect.maxY + margin
        let aboveY = selRect.minY - height - margin

        let y: CGFloat
        if belowY + height <= bounds.maxY - margin {
            y = belowY
        } else if aboveY >= bounds.minY + margin {
            y = aboveY
        } else {
            y = max(bounds.minY + margin, min(belowY, bounds.maxY - height - margin))
        }

        hostingView.frame = CGRect(x: x, y: y, width: width, height: height)
        targetView.addSubview(hostingView)
        self.toolbarView = hostingView
    }

    private func hideToolbar() {
        toolbarView?.removeFromSuperview()
        toolbarView = nil
    }

    private func resolvedActiveIndex() -> Int? {
        let mouse = NSEvent.mouseLocation
        if let idx = screenImages.firstIndex(where: { NSMouseInRect(mouse, $0.screen.frame, false) }) {
            return idx
        }
        if let idx = selectionViews.firstIndex(where: { $0.window?.isKeyWindow == true }) {
            return idx
        }
        return screenImages.isEmpty ? nil : 0
    }

    // MARK: - Actions

    private func cropAndCopy(selection: SelectionRect) {
        guard let index = activeIndex ?? resolvedActiveIndex(),
              screenImages.indices.contains(index) else { return }
        let screen = screenImages[index].screen
        let image = screenImages[index].image
        if let cropped = ImageCropper.crop(image: image, selection: selection, screen: screen) {
            ClipboardService.copy(image: cropped)
        }
    }

    private func copySelection() {
        if let selection = currentSelection {
            cropAndCopy(selection: selection)
        }
        dismiss()
    }

    private func saveSelection() {
        defer { dismiss() }
        guard let selection = currentSelection else { return }
        guard let index = activeIndex ?? resolvedActiveIndex(),
              screenImages.indices.contains(index) else { return }

        let screen = screenImages[index].screen
        let image = screenImages[index].image
        if let cropped = ImageCropper.crop(image: image, selection: selection, screen: screen) {
            ClipboardService.copy(image: cropped)
            FileService.save(image: cropped)
        }
    }
}
