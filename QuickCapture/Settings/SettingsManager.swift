import Foundation

final class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    private let defaults = UserDefaults.standard

    @Published var saveDirectory: String {
        didSet { defaults.set(saveDirectory, forKey: Constants.Keys.saveDirectory) }
    }

    @Published var showNotification: Bool {
        didSet { defaults.set(showNotification, forKey: Constants.Keys.showNotification) }
    }

    private init() {
        // Load saved values or use defaults
        self.saveDirectory = defaults.string(forKey: Constants.Keys.saveDirectory)
            ?? Constants.defaultSaveDirectory
        self.showNotification = defaults.bool(forKey: Constants.Keys.showNotification)
    }
}
