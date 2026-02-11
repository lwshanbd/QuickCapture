import SwiftUI
import ServiceManagement

struct LaunchAtLoginToggle: View {
    @State private var isEnabled: Bool = false

    var body: some View {
        Toggle("Launch at Login", isOn: $isEnabled)
            .onChange(of: isEnabled) { _, newValue in
                setLaunchAtLogin(newValue)
            }
            .onAppear {
                isEnabled = SMAppService.mainApp.status == .enabled
            }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("QuickCapture: Failed to update launch at login: \(error)")
            // Revert the toggle
            isEnabled = SMAppService.mainApp.status == .enabled
        }
    }
}
