import Foundation
import Combine
import UserNotifications

class TimerManager: ObservableObject {
    @Published var isRunning = false
    @Published var remainingTime: TimeInterval
    @Published var currentCycle = 0
    @Published var isBreakTime = false
    
    private(set) var settings: Settings
    private var timer: Timer?
    private var workDuration: TimeInterval { settings.workDuration }
    private var breakDuration: TimeInterval { settings.breakDuration }
    
    init(settings: Settings) {
        self.settings = settings
        self.remainingTime = settings.workDuration
    }
    
    func start() {
        guard !isRunning else { return }
        
        if remainingTime == 0 {
            remainingTime = workDuration
        }
        
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.remainingTime > 0 {
                self.remainingTime -= 1
            } else {
                self.handleTimerComplete()
            }
        }
    }
    
    func stop() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        
        if isBreakTime {
            isBreakTime = false
            remainingTime = workDuration
            WindowManager.shared.hideBreakOverlay()
        }
    }
    
    private func handleTimerComplete() {
        if isBreakTime {
            // Break finished, start work
            isBreakTime = false
            remainingTime = workDuration
            WindowManager.shared.hideBreakOverlay()
            notifyBreakComplete()
        } else if currentCycle < settings.maxCycles {
            // Work finished, start break
            currentCycle += 1
            isBreakTime = true
            remainingTime = breakDuration
            WindowManager.shared.showBreakOverlay()
            notifyBreakTime()
        } else {
            // All cycles complete
            stop()
            currentCycle = 0
            remainingTime = workDuration
            notifySessionComplete()
        }
    }
    
    private func notifyBreakTime() {
        let content = UNMutableNotificationContent()
        content.title = "Break Time!"
        content.body = "Take a \(Int(breakDuration/60)) minute break."
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: "breakTime", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    private func notifyBreakComplete() {
        let content = UNMutableNotificationContent()
        content.title = "Break Complete"
        content.body = "Time to get back to work!"
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: "breakComplete", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    private func notifySessionComplete() {
        let content = UNMutableNotificationContent()
        content.title = "Session Complete!"
        content.body = "Great job! You've completed all cycles."
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: "sessionComplete", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    deinit {
        timer?.invalidate()
    }
}
