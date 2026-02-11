import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = SettingsManager.shared

    var body: some View {
        TabView {
            GeneralSettingsView(settings: settings)
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            PermissionsSettingsView()
                .tabItem {
                    Label("Permissions", systemImage: "lock.shield")
                }
        }
        .frame(width: 450, height: 300)
    }
}

struct GeneralSettingsView: View {
    @ObservedObject var settings: SettingsManager

    var body: some View {
        Form {
            Section("Screenshot") {
                HStack {
                    TextField("Save Directory", text: $settings.saveDirectory)
                        .textFieldStyle(.roundedBorder)
                    Button("Browse...") {
                        chooseSaveDirectory()
                    }
                }
            }

            Section("Startup") {
                LaunchAtLoginToggle()
            }

            Section("Hotkey") {
                Text("Cmd + Ctrl + A")
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func chooseSaveDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true

        if panel.runModal() == .OK, let url = panel.url {
            settings.saveDirectory = url.path
        }
    }
}

struct PermissionsSettingsView: View {
    @State private var screenRecordingGranted = false

    var body: some View {
        Form {
            Section("Screen Recording") {
                HStack {
                    Image(systemName: screenRecordingGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(screenRecordingGranted ? .green : .red)
                    Text("Screen Recording Permission")
                    Spacer()
                    if !screenRecordingGranted {
                        Button("Open Settings") {
                            PermissionChecker.openScreenRecordingSettings()
                        }
                    }
                }
            }

            Section {
                Button("Refresh Permission Status") {
                    checkPermissions()
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            checkPermissions()
        }
    }

    private func checkPermissions() {
        // CGPreflightScreenCaptureAccess — silent check, no dialog
        screenRecordingGranted = PermissionChecker.isScreenRecordingGranted
    }
}
