import Foundation

enum AppSettings {
    private enum Keys {
        static let modelName = "openai_model_name"
    }

    static let defaultModelName = "gpt-4.1-nano"

    static var modelName: String {
        get {
            let stored = UserDefaults.standard.string(forKey: Keys.modelName)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return (stored?.isEmpty == false) ? stored! : defaultModelName
        }
        set {
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            UserDefaults.standard.set(
                trimmed.isEmpty ? defaultModelName : trimmed,
                forKey: Keys.modelName
            )
        }
    }
}
