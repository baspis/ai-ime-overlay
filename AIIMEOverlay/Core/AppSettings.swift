import Foundation

enum AppSettings {
    private enum Keys {
        static let modelName = "gemini_model_name"
    }

    /// Cheapest stable Flash model; ideal for short romaji → Japanese conversion.
    static let defaultModelName = "gemini-2.5-flash-lite"

    /// Slightly higher quality/cost alternative (change in Settings).
    static let recommendedUpgradeModelName = "gemini-3.1-flash-lite"

    static var modelName: String {
        get {
            let stored = UserDefaults.standard.string(forKey: Keys.modelName)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if let stored, !stored.isEmpty {
                // Migrate away from old OpenAI default if still stored.
                if stored.hasPrefix("gpt-") {
                    return defaultModelName
                }
                return stored
            }
            return defaultModelName
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
