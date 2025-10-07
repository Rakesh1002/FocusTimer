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
    
    // New managers
    var statisticsManager: StatisticsManager?
    var soundManager: SoundManager?
    var sessionJournal: SessionJournal?
    var breakActivityManager: BreakActivityManager?
    var presetManager: PresetManager?
    
    // Session tracking
    private var sessionStartTime: Date?
    private var totalWorkTime: TimeInterval = 0
    private var cyclesCompletedInSession = 0
    
    init(settings: Settings) {
        self.settings = settings
        self.remainingTime = settings.workDuration
    }
    
    func start() {
        guard !isRunning else { return }
        
        if remainingTime == 0 {
            remainingTime = workDuration
        }
        
        // Track session start
        if sessionStartTime == nil {
            sessionStartTime = Date()
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
        
        // Add timer to common run loop mode to ensure it keeps running when app is hidden
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    func stop() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        
        // Log session if it was a work session
        if !isBreakTime && sessionStartTime != nil {
            logSession(wasCompleted: false)
        }
        
        if isBreakTime {
            isBreakTime = false
            remainingTime = workDuration
            WindowManager.shared.hideBreakOverlay()
        }
        
        // Reset session tracking
        sessionStartTime = nil
        totalWorkTime = 0
        cyclesCompletedInSession = 0
    }
    
    private func handleTimerComplete() {
        if isBreakTime {
            // Break finished, start work
            isBreakTime = false
            remainingTime = workDuration
            WindowManager.shared.hideBreakOverlay()
            notifyBreakComplete()
            soundManager?.playBreakCompleteSound()
        } else if currentCycle < settings.maxCycles {
            // Work finished, start break
            totalWorkTime += workDuration
            cyclesCompletedInSession += 1
            currentCycle += 1
            isBreakTime = true
            // Select break duration (support long break)
            var selectedBreak = breakDuration
            if let preset = presetManager?.currentPreset,
               let long = preset.longBreakDuration {
                let nextCycle = currentCycle // already incremented above
                // Use a long break at cadence = preset.maxCycles, but not on the final session-ending break
                if nextCycle % preset.maxCycles == 0 && nextCycle < settings.maxCycles {
                    selectedBreak = long
                }
            }
            remainingTime = selectedBreak
            if settings.showBreakOverlay {
                WindowManager.shared.showBreakOverlay()
            }
            notifyBreakTime()
            soundManager?.playWorkCompleteSound()
        } else {
            // All cycles complete
            totalWorkTime += workDuration
            cyclesCompletedInSession += 1
            logSession(wasCompleted: true)
            stop()
            currentCycle = 0
            remainingTime = workDuration
            notifySessionComplete()
            soundManager?.playSessionCompleteSound()
        }
    }
    
    private func logSession(wasCompleted: Bool) {
        guard sessionStartTime != nil else { return }
        
        statisticsManager?.logSession(
            duration: totalWorkTime,
            breakDuration: breakDuration * TimeInterval(cyclesCompletedInSession),
            cyclesCompleted: cyclesCompletedInSession,
            wasCompleted: wasCompleted,
            taskLabel: nil
        )
        
        // Prompt for session journal if completed
        if wasCompleted {
            sessionJournal?.promptForNote(duration: totalWorkTime, cycles: cyclesCompletedInSession)
        }
        
        // Check for achievements
        if let achievements = statisticsManager?.checkAchievements(), !achievements.isEmpty {
            for achievement in achievements {
                notifyAchievement(achievement)
            }
        }
    }
    
    private func notifyBreakTime() {
        guard settings.breakNotifications else { return }
        let content = UNMutableNotificationContent()
        content.title = "Break Time!"
        content.body = "Take a \(Int(breakDuration/60)) minute break."
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: "breakTime", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    private func notifyBreakComplete() {
        guard settings.breakNotifications else { return }
        let content = UNMutableNotificationContent()
        content.title = "Break Complete"
        content.body = "Time to get back to work!"
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: "breakComplete", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    private func notifySessionComplete() {
        guard settings.sessionCompleteNotifications else { return }
        let content = UNMutableNotificationContent()
        content.title = "Session Complete!"
        content.body = "Great job! You've completed all cycles."
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: "sessionComplete", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    private func notifyAchievement(_ achievement: String) {
        let content = UNMutableNotificationContent()
        content.title = "Achievement Unlocked!"
        content.body = achievement
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: "achievement_\(UUID())", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Controls
    /// Skip the current break and immediately start the next work block without resetting session state
    func skipBreakStartWork() {
        guard isBreakTime else { return }
        isBreakTime = false
        remainingTime = workDuration
        WindowManager.shared.hideBreakOverlay()
        // ensure timer keeps running; if stopped, start it
        if timer == nil {
            start()
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}
