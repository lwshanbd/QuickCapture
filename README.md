# QuickCapture

## Regression checks

Run `bash scripts/test-selection.sh` from a logged-in macOS desktop session.
The check uses a generated image to exercise selection redraws, the size label,
Copy, Save, double-click confirmation, and Cancel. It restores the clipboard
afterward and writes test images to a temporary directory printed on completion.
