import Foundation
import AppKit

class AppCleanup {
    static let shared = AppCleanup()
    private var isSetup = false
    
    private init() {}
    
    func setup() {
        guard !isSetup else { return }
        isSetup = true
        
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { _ in
            WindowManager.shared.cleanup()
        }
    }
}
