import Foundation
import Combine

struct Task: Identifiable, Codable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var priority: Priority
    var estimatedPomodoros: Int
    var completedPomodoros: Int
    var dueDate: Date?
    var notes: String?
    var createdAt: Date
    var completedAt: Date?
    var tags: [String]
    
    enum Priority: Int, Codable, CaseIterable {
        case low = 0
        case medium = 1
        case high = 2
        case urgent = 3
        
        var displayName: String {
            switch self {
            case .low: return "Low"
            case .medium: return "Medium"
            case .high: return "High"
            case .urgent: return "Urgent"
            }
        }
        
        var color: String {
            switch self {
            case .low: return "gray"
            case .medium: return "blue"
            case .high: return "orange"
            case .urgent: return "red"
            }
        }
        
        var icon: String {
            switch self {
            case .low: return "arrow.down.circle"
            case .medium: return "equal.circle"
            case .high: return "arrow.up.circle"
            case .urgent: return "exclamationmark.circle"
            }
        }
    }
    
    init(
        id: UUID = UUID(),
        title: String,
        priority: Priority = .medium,
        estimatedPomodoros: Int = 1,
        dueDate: Date? = nil,
        notes: String? = nil,
        tags: [String] = []
    ) {
        self.id = id
        self.title = title
        self.isCompleted = false
        self.priority = priority
        self.estimatedPomodoros = estimatedPomodoros
        self.completedPomodoros = 0
        self.dueDate = dueDate
        self.notes = notes
        self.createdAt = Date()
        self.completedAt = nil
        self.tags = tags
    }
    
    var progress: Double {
        guard estimatedPomodoros > 0 else { return 0 }
        return Double(completedPomodoros) / Double(estimatedPomodoros)
    }
    
    var isOverdue: Bool {
        guard let due = dueDate, !isCompleted else { return false }
        return due < Date()
    }
    
    var isDueToday: Bool {
        guard let due = dueDate else { return false }
        return Calendar.current.isDateInToday(due)
    }
    
    var isDueSoon: Bool {
        guard let due = dueDate, !isCompleted else { return false }
        let daysUntil = Calendar.current.dateComponents([.day], from: Date(), to: due).day ?? 0
        return daysUntil >= 0 && daysUntil <= 3
    }
}

class TaskManager: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var currentTask: Task?
    @Published var filter: TaskFilter = .all
    @Published var sortBy: TaskSort = .priority
    
    private let defaults = UserDefaults.app
    private let tasksKey = "focusTasks"
    
    enum TaskFilter {
        case all
        case active
        case completed
        case today
        case overdue
        case tag(String)
    }
    
    enum TaskSort {
        case priority
        case dueDate
        case created
        case title
    }
    
    init() {
        loadTasks()
    }
    
    // MARK: - Task Management
    
    func addTask(_ task: Task) {
        tasks.insert(task, at: 0)
        saveTasks()
    }
    
    func updateTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
            saveTasks()
        }
    }
    
    func deleteTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
        if currentTask?.id == task.id {
            currentTask = nil
        }
        saveTasks()
    }
    
    func toggleCompletion(_ task: Task) {
        var updatedTask = task
        updatedTask.isCompleted.toggle()
        updatedTask.completedAt = updatedTask.isCompleted ? Date() : nil
        updateTask(updatedTask)
    }
    
    func incrementPomodoro(_ task: Task) {
        var updatedTask = task
        updatedTask.completedPomodoros += 1
        
        // Auto-complete if reached estimated pomodoros
        if updatedTask.completedPomodoros >= updatedTask.estimatedPomodoros {
            updatedTask.isCompleted = true
            updatedTask.completedAt = Date()
        }
        
        updateTask(updatedTask)
    }
    
    func setCurrentTask(_ task: Task?) {
        currentTask = task
    }
    
    // MARK: - Filtering & Sorting
    
    var filteredTasks: [Task] {
        let filtered: [Task]
        
        switch filter {
        case .all:
            filtered = tasks
        case .active:
            filtered = tasks.filter { !$0.isCompleted }
        case .completed:
            filtered = tasks.filter { $0.isCompleted }
        case .today:
            filtered = tasks.filter { $0.isDueToday && !$0.isCompleted }
        case .overdue:
            filtered = tasks.filter { $0.isOverdue }
        case .tag(let tag):
            filtered = tasks.filter { $0.tags.contains(tag) }
        }
        
        return sortTasks(filtered)
    }
    
    private func sortTasks(_ tasks: [Task]) -> [Task] {
        switch sortBy {
        case .priority:
            return tasks.sorted { $0.priority.rawValue > $1.priority.rawValue }
        case .dueDate:
            return tasks.sorted { task1, task2 in
                guard let due1 = task1.dueDate else { return false }
                guard let due2 = task2.dueDate else { return true }
                return due1 < due2
            }
        case .created:
            return tasks.sorted { $0.createdAt > $1.createdAt }
        case .title:
            return tasks.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
    }
    
    // MARK: - Statistics
    
    var activeTaskCount: Int {
        tasks.filter { !$0.isCompleted }.count
    }
    
    var completedTaskCount: Int {
        tasks.filter { $0.isCompleted }.count
    }
    
    var todayTaskCount: Int {
        tasks.filter { $0.isDueToday && !$0.isCompleted }.count
    }
    
    var overdueTaskCount: Int {
        tasks.filter { $0.isOverdue }.count
    }
    
    var totalEstimatedPomodoros: Int {
        tasks.filter { !$0.isCompleted }.reduce(0) { $0 + $1.estimatedPomodoros }
    }
    
    var totalCompletedPomodoros: Int {
        tasks.reduce(0) { $0 + $1.completedPomodoros }
    }
    
    // MARK: - Smart Suggestions
    
    func suggestNextTask() -> Task? {
        let activeTasks = tasks.filter { !$0.isCompleted }
        
        // Priority order: overdue > due today > high priority > in progress
        if let overdue = activeTasks.first(where: { $0.isOverdue }) {
            return overdue
        }
        
        if let dueToday = activeTasks.first(where: { $0.isDueToday }) {
            return dueToday
        }
        
        if let inProgress = activeTasks.first(where: { $0.completedPomodoros > 0 && $0.completedPomodoros < $0.estimatedPomodoros }) {
            return inProgress
        }
        
        return activeTasks.sorted { $0.priority.rawValue > $1.priority.rawValue }.first
    }
    
    func getTasksForToday() -> [Task] {
        tasks.filter { task in
            !task.isCompleted && (task.isDueToday || task.priority == .urgent)
        }.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
    
    // MARK: - Tags
    
    var allTags: [String] {
        let tagSet = Set(tasks.flatMap { $0.tags })
        return Array(tagSet).sorted()
    }
    
    func tasksWithTag(_ tag: String) -> [Task] {
        tasks.filter { $0.tags.contains(tag) }
    }
    
    // MARK: - Persistence
    
    private func saveTasks() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            defaults.set(encoded, forKey: tasksKey)
        }
    }
    
    private func loadTasks() {
        if let data = defaults.data(forKey: tasksKey),
           let decoded = try? JSONDecoder().decode([Task].self, from: data) {
            tasks = decoded
        }
    }
    
    // MARK: - Bulk Operations
    
    func deleteCompletedTasks() {
        tasks.removeAll { $0.isCompleted }
        saveTasks()
    }
    
    func archiveCompletedTasks() {
        // Future: Move to archive instead of delete
        deleteCompletedTasks()
    }
    
    // MARK: - Import/Export
    
    func exportToJSON() -> Data? {
        try? JSONEncoder().encode(tasks)
    }
    
    func importFromJSON(_ data: Data) throws {
        let importedTasks = try JSONDecoder().decode([Task].self, from: data)
        tasks.append(contentsOf: importedTasks)
        saveTasks()
    }
}

