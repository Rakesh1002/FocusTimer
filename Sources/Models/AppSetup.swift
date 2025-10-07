import Foundation
import UserNotifications

@MainActor
class AppSetup: ObservableObject {
    static let shared = AppSetup()
    @Published private(set) var isInitialized = false
    
    private init() {}
    
    func initialize(timerManager: TimerManager) async {
        guard !isInitialized else { return }
        
        // Request notification permissions
        do {
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()
            
            if settings.authorizationStatus != .authorized {
                let granted = try await center.requestAuthorization(options: [.alert, .sound])
                if !granted {
                    print("Notification permission denied")
                }
            }
        } catch {
            print("Error requesting notification permission: \(error)")
        }
        
        // Initialize window manager with timer manager
        DispatchQueue.main.async {
            WindowManager.shared.setTimerManager(timerManager)
            WindowManager.shared.showTimeDisplay()
        }
        
        isInitialized = true
    }
}
