import Foundation

struct BreakActivity: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let duration: Int // in minutes
    let category: Category
    let icon: String
    var isCustom: Bool
    
    enum Category: String, Codable, CaseIterable {
        case physical = "Physical"
        case mental = "Mental"
        case social = "Social"
        case creative = "Creative"
        case health = "Health"
        
        var icon: String {
            switch self {
            case .physical: return "figure.walk"
            case .mental: return "brain.head.profile"
            case .social: return "person.2.fill"
            case .creative: return "paintbrush.fill"
            case .health: return "heart.fill"
            }
        }
        
        var color: String {
            switch self {
            case .physical: return "blue"
            case .mental: return "purple"
            case .social: return "green"
            case .creative: return "orange"
            case .health: return "red"
            }
        }
    }
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        duration: Int,
        category: Category,
        icon: String,
        isCustom: Bool = false
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.duration = duration
        self.category = category
        self.icon = icon
        self.isCustom = isCustom
    }
    
    // Built-in activities
    static let builtInActivities: [BreakActivity] = [
        // Physical
        BreakActivity(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            title: "Stretch",
            description: "Stand up and stretch your arms, neck, and back",
            duration: 5,
            category: .physical,
            icon: "figure.flexibility"
        ),
        BreakActivity(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            title: "Quick Walk",
            description: "Take a short walk around your space",
            duration: 10,
            category: .physical,
            icon: "figure.walk"
        ),
        BreakActivity(
            id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            title: "Desk Exercises",
            description: "Do 10 pushups, squats, or desk yoga",
            duration: 5,
            category: .physical,
            icon: "dumbbell.fill"
        ),
        
        // Mental
        BreakActivity(
            id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
            title: "20-20-20 Rule",
            description: "Look at something 20 feet away for 20 seconds",
            duration: 1,
            category: .mental,
            icon: "eye.fill"
        ),
        BreakActivity(
            id: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!,
            title: "Deep Breathing",
            description: "Take 5 deep breaths: inhale for 4, hold for 4, exhale for 4",
            duration: 2,
            category: .mental,
            icon: "wind"
        ),
        BreakActivity(
            id: UUID(uuidString: "66666666-6666-6666-6666-666666666666")!,
            title: "Quick Meditation",
            description: "Close your eyes and focus on your breath",
            duration: 5,
            category: .mental,
            icon: "sparkles"
        ),
        
        // Health
        BreakActivity(
            id: UUID(uuidString: "77777777-7777-7777-7777-777777777777")!,
            title: "Hydrate",
            description: "Drink a full glass of water",
            duration: 2,
            category: .health,
            icon: "drop.fill"
        ),
        BreakActivity(
            id: UUID(uuidString: "88888888-8888-8888-8888-888888888888")!,
            title: "Healthy Snack",
            description: "Eat some fruit, nuts, or a healthy snack",
            duration: 5,
            category: .health,
            icon: "leaf.fill"
        ),
        
        // Social
        BreakActivity(
            id: UUID(uuidString: "99999999-9999-9999-9999-999999999999")!,
            title: "Quick Chat",
            description: "Have a brief conversation with someone",
            duration: 5,
            category: .social,
            icon: "message.fill"
        ),
        BreakActivity(
            id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!,
            title: "Call Someone",
            description: "Make a quick call to a friend or family member",
            duration: 10,
            category: .social,
            icon: "phone.fill"
        ),
        
        // Creative
        BreakActivity(
            id: UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!,
            title: "Doodle",
            description: "Draw or sketch something for fun",
            duration: 5,
            category: .creative,
            icon: "pencil.and.outline"
        ),
        BreakActivity(
            id: UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!,
            title: "Listen to Music",
            description: "Play your favorite song and enjoy",
            duration: 5,
            category: .creative,
            icon: "music.note"
        )
    ]
}

class BreakActivityManager: ObservableObject {
    @Published var activities: [BreakActivity] = []
    @Published var suggestedActivity: BreakActivity?
    @Published var completedActivities: [UUID: Int] = [:] // ID -> completion count
    
    private let defaults = UserDefaults.app
    private let activitiesKey = "breakActivities"
    private let completedKey = "completedActivities"
    
    init() {
        loadActivities()
        loadCompletedActivities()
        
        // Add built-in activities if not present
        for builtIn in BreakActivity.builtInActivities {
            if !activities.contains(where: { $0.id == builtIn.id }) {
                activities.append(builtIn)
            }
        }
    }
    
    // MARK: - Activity Management
    
    func addActivity(_ activity: BreakActivity) {
        activities.append(activity)
        saveActivities()
    }
    
    func updateActivity(_ activity: BreakActivity) {
        if let index = activities.firstIndex(where: { $0.id == activity.id }) {
            activities[index] = activity
            saveActivities()
        }
    }
    
    func deleteActivity(_ activity: BreakActivity) {
        guard activity.isCustom else { return }
        activities.removeAll { $0.id == activity.id }
        saveActivities()
    }
    
    // MARK: - Suggestions
    
    func suggestActivity(for duration: TimeInterval) -> BreakActivity {
        let breakMinutes = Int(duration / 60)
        
        // Filter activities that fit within break duration
        let suitable = activities.filter { $0.duration <= breakMinutes }
        
        // Prefer less-completed activities
        let sorted = suitable.sorted { activity1, activity2 in
            let count1 = completedActivities[activity1.id] ?? 0
            let count2 = completedActivities[activity2.id] ?? 0
            return count1 < count2
        }
        
        // Return random from top 5 least completed
        let topFive = Array(sorted.prefix(5))
        return topFive.randomElement() ?? BreakActivity.builtInActivities[0]
    }
    
    func suggestRandomActivity() -> BreakActivity {
        activities.randomElement() ?? BreakActivity.builtInActivities[0]
    }
    
    func markActivityCompleted(_ activity: BreakActivity) {
        let currentCount = completedActivities[activity.id] ?? 0
        completedActivities[activity.id] = currentCount + 1
        saveCompletedActivities()
    }
    
    // MARK: - Statistics
    
    func activitiesByCategory(_ category: BreakActivity.Category) -> [BreakActivity] {
        activities.filter { $0.category == category }
    }
    
    var customActivities: [BreakActivity] {
        activities.filter { $0.isCustom }
    }
    
    var builtInActivities: [BreakActivity] {
        activities.filter { !$0.isCustom }
    }
    
    var mostCompletedActivity: BreakActivity? {
        guard !completedActivities.isEmpty else { return nil }
        let sorted = completedActivities.sorted { $0.value > $1.value }
        guard let topId = sorted.first?.key else { return nil }
        return activities.first { $0.id == topId }
    }
    
    var totalActivitiesCompleted: Int {
        completedActivities.values.reduce(0, +)
    }
    
    // MARK: - Persistence
    
    private func saveActivities() {
        // Only save custom activities
        let customActivities = activities.filter { $0.isCustom }
        if let encoded = try? JSONEncoder().encode(customActivities) {
            defaults.set(encoded, forKey: activitiesKey)
        }
    }
    
    private func loadActivities() {
        if let data = defaults.data(forKey: activitiesKey),
           let decoded = try? JSONDecoder().decode([BreakActivity].self, from: data) {
            activities = decoded
        }
    }
    
    private func saveCompletedActivities() {
        let dict = completedActivities.mapKeys { $0.uuidString }
        defaults.set(dict, forKey: completedKey)
    }
    
    private func loadCompletedActivities() {
        if let dict = defaults.dictionary(forKey: completedKey) as? [String: Int] {
            completedActivities = dict.compactMapKeys { UUID(uuidString: $0) }
        }
    }
}

// Helper extensions
extension Dictionary {
    func mapKeys<T: Hashable>(_ transform: (Key) -> T) -> [T: Value] {
        var result: [T: Value] = [:]
        for (key, value) in self {
            result[transform(key)] = value
        }
        return result
    }
    
    func compactMapKeys<T: Hashable>(_ transform: (Key) -> T?) -> [T: Value] {
        var result: [T: Value] = [:]
        for (key, value) in self {
            if let newKey = transform(key) {
                result[newKey] = value
            }
        }
        return result
    }
}

