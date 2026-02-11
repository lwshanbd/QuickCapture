import SwiftUI

@main
struct QuickCaptureApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra(Constants.appName, systemImage: Constants.menuBarIcon) {
            MenuBarView(appDelegate: appDelegate)
        }
        Settings {
            SettingsView()
        }
    }
}

struct MenuBarView: View {
    let appDelegate: AppDelegate

    var body: some View {
        Button("Capture Screenshot") {
            appDelegate.triggerCapture()
        }
        .keyboardShortcut("a", modifiers: [.command, .control])

        Divider()

        SettingsLink {
            Text("Settings...")
        }

        Divider()

        Button("Quit QuickCapture") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
