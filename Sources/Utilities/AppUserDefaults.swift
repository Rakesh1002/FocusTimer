import Foundation

/// Shared UserDefaults configuration for the app
/// Ensures all models read/write from the correct domain
extension UserDefaults {
    static let app: UserDefaults = {
        // Use the actual bundle identifier (unquest.focusly)
        // This ensures data persists correctly across updates
        if let suite = UserDefaults(suiteName: "unquest.focusly") {
            return suite
        }
        return .standard
    }()
}

