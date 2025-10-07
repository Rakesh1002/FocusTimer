import Foundation
import UserNotifications

/// Centralized notification manager for tasks, calendar events, and statistics
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var areNotificationsEnabled = false
    private let center = UNUserNotificationCenter.current()
    
    // Notification categories
    enum NotificationType: String {
        case taskDue = "task_due"
        case taskOverdue = "task_overdue"
        case calendarReminder = "calendar_reminder"
        case dailySummary = "daily_summary"
        case weeklySummary = "weekly_summary"
        case achievement = "achievement"
        case breakTime = "break_time"
        case sessionComplete = "session_complete"
    }
    
    private init() {
        checkNotificationStatus()
        setupNotificationCategories()
    }
    
    // MARK: - Permission Management
    
    func checkNotificationStatus() {
        center.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.areNotificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                self.areNotificationsEnabled = granted
            }
            return granted
        } catch {
            print("❌ Notification permission error: \(error)")
            return false
        }
    }
    
    private func setupNotificationCategories() {
        // Task actions
        let completeAction = UNNotificationAction(
            identifier: "COMPLETE_TASK",
            title: "Mark Complete",
            options: [.foreground]
        )
        
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_TASK",
            title: "Snooze 1 Hour",
            options: []
        )
        
        let taskCategory = UNNotificationCategory(
            identifier: "TASK_REMINDER",
            actions: [completeAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Calendar actions
        let viewCalendarAction = UNNotificationAction(
            identifier: "VIEW_CALENDAR",
            title: "View Calendar",
            options: [.foreground]
        )
        
        let calendarCategory = UNNotificationCategory(
            identifier: "CALENDAR_REMINDER",
            actions: [viewCalendarAction],
            intentIdentifiers: [],
            options: []
        )
        
        center.setNotificationCategories([taskCategory, calendarCategory])
    }
    
    // MARK: - Task Notifications
    
    /// Schedule notification when task is due
    func scheduleTaskDueNotification(task: Task) {
        guard let dueDate = task.dueDate else { return }
        guard dueDate > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Task Due Soon"
        content.body = "📋 \(task.title)"
        content.sound = .default
        content.categoryIdentifier = "TASK_REMINDER"
        content.userInfo = ["taskId": task.id.uuidString, "type": NotificationType.taskDue.rawValue]
        
        // Badge for priority
        if task.priority == .urgent {
            content.badge = 1
        }
        
        // Schedule 30 minutes before due
        let triggerDate = dueDate.addingTimeInterval(-1800)
        if triggerDate > Date() {
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
            let request = UNNotificationRequest(
                identifier: "task_\(task.id.uuidString)",
                content: content,
                trigger: trigger
            )
            
            center.add(request) { error in
                if let error = error {
                    print("❌ Error scheduling task notification: \(error)")
                } else {
                    print("✅ Task notification scheduled for \(task.title)")
                }
            }
        }
    }
    
    /// Notify about overdue tasks (daily at 9 AM)
    func scheduleOverdueTasksNotification(overdueCount: Int) {
        guard overdueCount > 0 else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Overdue Tasks"
        content.body = "⚠️ You have \(overdueCount) overdue task\(overdueCount > 1 ? "s" : "")"
        content.sound = .default
        content.badge = NSNumber(value: overdueCount)
        content.userInfo = ["type": NotificationType.taskOverdue.rawValue]
        
        // Daily at 9 AM
        var dateComponents = DateComponents()
        dateComponents.hour = 9
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "overdue_tasks_daily",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("❌ Error scheduling overdue notification: \(error)")
            }
        }
    }
    
    /// Cancel task notification
    func cancelTaskNotification(taskId: UUID) {
        center.removePendingNotificationRequests(withIdentifiers: ["task_\(taskId.uuidString)"])
    }
    
    // MARK: - Calendar Notifications
    
    /// Schedule notification before calendar event
    func scheduleCalendarReminder(event: CalendarEvent, minutesBefore: Int = 15) {
        guard event.startDate > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Upcoming Meeting"
        content.body = "📅 \(event.title) in \(minutesBefore) minutes"
        content.sound = .default
        content.categoryIdentifier = "CALENDAR_REMINDER"
        content.userInfo = [
            "eventId": event.id,
            "type": NotificationType.calendarReminder.rawValue
        ]
        
        let triggerDate = event.startDate.addingTimeInterval(-Double(minutesBefore * 60))
        if triggerDate > Date() {
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
            let request = UNNotificationRequest(
                identifier: "calendar_\(event.id)",
                content: content,
                trigger: trigger
            )
            
            center.add(request) { error in
                if let error = error {
                    print("❌ Error scheduling calendar notification: \(error)")
                } else {
                    print("✅ Calendar notification scheduled for \(event.title)")
                }
            }
        }
    }
    
    /// Notify about suggested focus times based on calendar
    func notifySuggestedFocusTime(time: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Ideal Focus Time"
        content.body = "🧘 Perfect time for a focus session - no meetings scheduled!"
        content.sound = .default
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "focus_suggestion_\(time.timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        center.add(request)
    }
    
    // MARK: - Statistics Notifications
    
    /// Daily summary at end of day (8 PM)
    func scheduleDailySummary(stats: DailyStats) {
        let content = UNMutableNotificationContent()
        content.title = "Daily Summary"
        
        if stats.totalFocusTime > 0 {
            content.body = "🎯 Today: \(stats.formattedFocusTime) of focus time across \(stats.sessionsCompleted) sessions"
        } else {
            content.body = "💡 No focus sessions today. Try one tomorrow!"
        }
        
        content.sound = .default
        content.userInfo = ["type": NotificationType.dailySummary.rawValue]
        
        // Daily at 8 PM
        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "daily_summary",
            content: content,
            trigger: trigger
        )
        
        center.add(request)
    }
    
    /// Weekly summary on Sunday at 6 PM
    func scheduleWeeklySummary(totalHours: Double, sessionsCount: Int, streak: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Weekly Progress"
        content.body = """
        📊 This week:
        • \(String(format: "%.1f", totalHours)) hours focused
        • \(sessionsCount) sessions completed
        • \(streak) day streak 🔥
        """
        content.sound = .default
        content.userInfo = ["type": NotificationType.weeklySummary.rawValue]
        
        // Sundays at 6 PM
        var dateComponents = DateComponents()
        dateComponents.weekday = 1 // Sunday
        dateComponents.hour = 18
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "weekly_summary",
            content: content,
            trigger: trigger
        )
        
        center.add(request)
    }
    
    /// Milestone achievements
    func notifyAchievement(title: String, description: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = description
        content.sound = .default
        content.userInfo = ["type": NotificationType.achievement.rawValue]
        
        let request = UNNotificationRequest(
            identifier: "achievement_\(UUID().uuidString)",
            content: content,
            trigger: nil // Immediate
        )
        
        center.add(request)
    }
    
    // MARK: - Timer Notifications (existing)
    
    func notifyBreakTime(duration: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = "Break Time!"
        content.body = "Take a \(Int(duration/60)) minute break 🧘"
        content.sound = .default
        content.userInfo = ["type": NotificationType.breakTime.rawValue]
        
        let request = UNNotificationRequest(
            identifier: "break_time",
            content: content,
            trigger: nil
        )
        
        center.add(request)
    }
    
    func notifySessionComplete(cycles: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Session Complete!"
        content.body = "🎉 Great job! You completed \(cycles) work blocks"
        content.sound = .default
        content.userInfo = ["type": NotificationType.sessionComplete.rawValue]
        
        let request = UNNotificationRequest(
            identifier: "session_complete",
            content: content,
            trigger: nil
        )
        
        center.add(request)
    }
    
    // MARK: - Utility Functions
    
    /// Get all pending notifications
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await center.pendingNotificationRequests()
    }
    
    /// Cancel specific notification
    func cancelNotification(identifier: String) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    /// Cancel all notifications of a type
    func cancelNotifications(ofType type: NotificationType) {
        center.getPendingNotificationRequests { [weak self] requests in
            guard let self = self else { return }
            let identifiers = requests.filter { request in
                (request.content.userInfo["type"] as? String) == type.rawValue
            }.map { $0.identifier }
            
            if !identifiers.isEmpty {
                self.center.removePendingNotificationRequests(withIdentifiers: identifiers)
            }
        }
    }
    
    /// Clear all pending notifications
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }
    
    /// Clear delivered notifications from notification center
    func clearDeliveredNotifications() {
        center.removeAllDeliveredNotifications()
    }
}

