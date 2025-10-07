import Foundation
import Combine

struct FocusSession: Codable, Identifiable {
    let id: UUID
    let date: Date
    let duration: TimeInterval
    let breakDuration: TimeInterval
    let cyclesCompleted: Int
    let wasCompleted: Bool
    let taskLabel: String?
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        duration: TimeInterval,
        breakDuration: TimeInterval,
        cyclesCompleted: Int,
        wasCompleted: Bool,
        taskLabel: String? = nil
    ) {
        self.id = id
        self.date = date
        self.duration = duration
        self.breakDuration = breakDuration
        self.cyclesCompleted = cyclesCompleted
        self.wasCompleted = wasCompleted
        self.taskLabel = taskLabel
    }
}

struct DailyStats: Codable, Identifiable {
    var id: Date { date }
    let date: Date
    let totalFocusTime: TimeInterval
    let sessionsCompleted: Int
    let cyclesCompleted: Int
    
    var formattedFocusTime: String {
        let hours = Int(totalFocusTime) / 3600
        let minutes = (Int(totalFocusTime) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

class StatisticsManager: ObservableObject {
    @Published var sessions: [FocusSession] = []
    @Published var totalFocusTime: TimeInterval = 0
    @Published var totalSessions: Int = 0
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    
    private let defaults = UserDefaults.app
    private let sessionsKey = "focusSessions"
    
    init() {
        loadSessions()
        calculateStats()
    }
    
    // MARK: - Session Management
    
    func clearAllStats() {
        sessions = []
        totalFocusTime = 0
        totalSessions = 0
        currentStreak = 0
        longestStreak = 0
        saveSessions()
    }
    
    func logSession(
        duration: TimeInterval,
        breakDuration: TimeInterval,
        cyclesCompleted: Int,
        wasCompleted: Bool,
        taskLabel: String? = nil
    ) {
        let session = FocusSession(
            date: Date(),
            duration: duration,
            breakDuration: breakDuration,
            cyclesCompleted: cyclesCompleted,
            wasCompleted: wasCompleted,
            taskLabel: taskLabel
        )
        
        sessions.insert(session, at: 0) // Most recent first
        saveSessions()
        calculateStats()
    }
    
    // MARK: - Statistics Calculation
    
    func calculateStats() {
        totalFocusTime = sessions.reduce(0) { $0 + $1.duration }
        totalSessions = sessions.count
        
        // Calculate streaks
        calculateStreaks()
    }
    
    private func calculateStreaks() {
        guard !sessions.isEmpty else {
            currentStreak = 0
            longestStreak = 0
            return
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Group sessions by day
        var sessionsByDay: [Date: [FocusSession]] = [:]
        for session in sessions {
            let day = calendar.startOfDay(for: session.date)
            sessionsByDay[day, default: []].append(session)
        }
        
        // Calculate current streak
        var streak = 0
        var checkDate = today
        
        while sessionsByDay[checkDate] != nil {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previousDay
        }
        
        currentStreak = streak
        
        // Calculate longest streak
        var maxStreak = 0
        var tempStreak = 0
        let sortedDates = sessionsByDay.keys.sorted()
        
        for (index, date) in sortedDates.enumerated() {
            if index == 0 {
                tempStreak = 1
            } else {
                let previousDate = sortedDates[index - 1]
                if calendar.dateComponents([.day], from: previousDate, to: date).day == 1 {
                    tempStreak += 1
                } else {
                    maxStreak = max(maxStreak, tempStreak)
                    tempStreak = 1
                }
            }
        }
        
        longestStreak = max(maxStreak, tempStreak)
    }
    
    // MARK: - Daily Statistics
    
    func getDailyStats(for date: Date) -> DailyStats {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let daySessions = sessions.filter { session in
            session.date >= startOfDay && session.date < endOfDay
        }
        
        let totalTime = daySessions.reduce(0) { $0 + $1.duration }
        let completed = daySessions.filter { $0.wasCompleted }.count
        let cycles = daySessions.reduce(0) { $0 + $1.cyclesCompleted }
        
        return DailyStats(
            date: startOfDay,
            totalFocusTime: totalTime,
            sessionsCompleted: completed,
            cyclesCompleted: cycles
        )
    }
    
    func getWeeklyStats() -> [DailyStats] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return (0..<7).compactMap { daysAgo in
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else {
                return nil
            }
            return getDailyStats(for: date)
        }.reversed()
    }
    
    func getMonthlyStats() -> [DailyStats] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return (0..<30).compactMap { daysAgo in
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else {
                return nil
            }
            return getDailyStats(for: date)
        }.reversed()
    }
    
    // MARK: - Export
    
    func exportToCSV() -> String {
        var csv = "Date,Duration (minutes),Break Duration (minutes),Cycles,Completed,Task\n"
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        
        for session in sessions {
            let date = formatter.string(from: session.date)
            let duration = Int(session.duration / 60)
            let breakDuration = Int(session.breakDuration / 60)
            let completed = session.wasCompleted ? "Yes" : "No"
            let task = session.taskLabel ?? ""
            
            csv += "\(date),\(duration),\(breakDuration),\(session.cyclesCompleted),\(completed),\(task)\n"
        }
        
        return csv
    }
    
    func exportToJSON() -> Data? {
        try? JSONEncoder().encode(sessions)
    }
    
    // MARK: - Persistence
    
    private func saveSessions() {
        if let encoded = try? JSONEncoder().encode(sessions) {
            defaults.set(encoded, forKey: sessionsKey)
        }
    }
    
    private func loadSessions() {
        if let data = defaults.data(forKey: sessionsKey),
           let decoded = try? JSONDecoder().decode([FocusSession].self, from: data) {
            sessions = decoded
        }
    }
    
    // MARK: - Achievements (Future)
    
    func checkAchievements() -> [String] {
        var achievements: [String] = []
        
        if totalSessions >= 1 && totalSessions < 2 {
            achievements.append("🏆 First Focus - Completed your first session!")
        }
        
        if currentStreak >= 7 {
            achievements.append("🔥 Hot Streak - 7 days in a row!")
        }
        
        if totalFocusTime >= 100 * 3600 { // 100 hours
            achievements.append("🚀 Power User - 100 hours of focus!")
        }
        
        return achievements
    }
}

