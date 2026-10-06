#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
test_dir=$(mktemp -d /tmp/QuickCaptureSelectionTests.XXXXXX)
swiftc -O -module-cache-path "$test_dir/ModuleCache" \
  QuickCapture/Overlay/*.swift QuickCapture/Models/SelectionRect.swift \
  QuickCapture/Utilities/Constants.swift QuickCapture/Utilities/ImageCropper.swift \
  QuickCapture/Services/ClipboardService.swift QuickCapture/Services/FileService.swift \
  QuickCapture/Settings/SettingsManager.swift Tests/SelectionRenderingTests.swift \
  -o "$test_dir/SelectionRenderingTests"
"$test_dir/SelectionRenderingTests" "$test_dir/output"
printf 'Test artifacts: %s/output\n' "$test_dir"
