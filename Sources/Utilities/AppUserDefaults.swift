import Foundation

/// Shared UserDefaults configuration for the app
/// Ensures all models read/write from the correct domain
extension UserDefaults {
    static let app: UserDefaults = {
        // Try to use suite name first (for app groups), fall back to standard
        if let suite = UserDefaults(suiteName: "com.unquest.focusly") {
            return suite
        }
        return .standard
    }()
}

