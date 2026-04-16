# QuickCapture

## 构建与安装

当用户要求"编译安装"或类似操作时，执行以下步骤：

1. **在 `/tmp` 下构建**（不要用项目目录下的 `build/`）。项目位于 `~/Documents/GitHub.nosync/` 下，被 iCloud/fileprovider 管理，会给产物附加 `com.apple.FinderInfo` / `com.apple.fileprovider.fpfs#P` 等扩展属性，导致 `codesign` 报 `resource fork, Finder information, or similar detritus not allowed` 失败。

   ```bash
   xcodebuild -project QuickCapture.xcodeproj -scheme QuickCapture \
     -configuration Release -derivedDataPath /tmp/QuickCaptureBuild build
   ```

2. **安装到 `~/Applications/`**（不是 `/Applications/`）：

   ```bash
   rm -rf ~/Applications/QuickCapture.app
   cp -R /tmp/QuickCaptureBuild/Build/Products/Release/QuickCapture.app ~/Applications/
   ```
