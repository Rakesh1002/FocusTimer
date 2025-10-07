import Foundation

struct SessionNote: Identifiable, Codable {
    let id: UUID
    let date: Date
    let sessionDuration: TimeInterval
    let cyclesCompleted: Int
    var note: String
    var mood: Mood?
    var tags: [String]
    var taskCompleted: String?
    
    enum Mood: String, Codable, CaseIterable {
        case great = "😊"
        case good = "🙂"
        case okay = "😐"
        case tired = "😴"
        case frustrated = "😤"
        
        var description: String {
            switch self {
            case .great: return "Great"
            case .good: return "Good"
            case .okay: return "Okay"
            case .tired: return "Tired"
            case .frustrated: return "Frustrated"
            }
        }

        // Accept both emoji (app native) and word values from mock data
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)

            // Exact emoji match first (native format)
            if let mood = Mood(rawValue: raw) {
                self = mood
                return
            }

            // Support words from mock script (e.g., "great", "good", ...)
            switch raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            case "great":
                self = .great
            case "good":
                self = .good
            case "ok", "okay":
                self = .okay
            case "tired":
                self = .tired
            case "frustrated":
                self = .frustrated
            default:
                // Fallback: try decoding as emoji string again or throw
                if let mood = Mood(rawValue: raw) {
                    self = mood
                } else {
                    throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unrecognized mood value: \(raw)")
                }
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(self.rawValue)
        }
    }
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        sessionDuration: TimeInterval,
        cyclesCompleted: Int,
        note: String = "",
        mood: Mood? = nil,
        tags: [String] = [],
        taskCompleted: String? = nil
    ) {
        self.id = id
        self.date = date
        self.sessionDuration = sessionDuration
        self.cyclesCompleted = cyclesCompleted
        self.note = note
        self.mood = mood
        self.tags = tags
        self.taskCompleted = taskCompleted
    }
}

class SessionJournal: ObservableObject {
    @Published var notes: [SessionNote] = []
    @Published var showJournalPrompt = false
    @Published var pendingSession: (duration: TimeInterval, cycles: Int)?
    
    private let defaults = UserDefaults.app
    private let notesKey = "sessionNotes"
    
    init() {
        loadNotes()
    }
    
    // MARK: - Note Management
    
    func addNote(_ note: SessionNote) {
        notes.insert(note, at: 0)
        saveNotes()
    }
    
    func updateNote(_ note: SessionNote) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index] = note
            saveNotes()
        }
    }
    
    func deleteNote(_ note: SessionNote) {
        notes.removeAll { $0.id == note.id }
        saveNotes()
    }
    
    // MARK: - Session Completion
    
    func promptForNote(duration: TimeInterval, cycles: Int) {
        pendingSession = (duration, cycles)
        showJournalPrompt = true
    }
    
    func skipNote() {
        pendingSession = nil
        showJournalPrompt = false
    }
    
    func saveSessionNote(note: String, mood: SessionNote.Mood?, tags: [String], taskCompleted: String?) {
        guard let session = pendingSession else { return }
        
        let sessionNote = SessionNote(
            sessionDuration: session.duration,
            cyclesCompleted: session.cycles,
            note: note,
            mood: mood,
            tags: tags,
            taskCompleted: taskCompleted
        )
        
        addNote(sessionNote)
        pendingSession = nil
        showJournalPrompt = false
    }
    
    // MARK: - Analytics
    
    func notesForDate(_ date: Date) -> [SessionNote] {
        let calendar = Calendar.current
        return notes.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }
    
    func notesForWeek() -> [SessionNote] {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return notes.filter { $0.date >= weekAgo }
    }
    
    func notesWithMood(_ mood: SessionNote.Mood) -> [SessionNote] {
        notes.filter { $0.mood == mood }
    }
    
    func notesWithTag(_ tag: String) -> [SessionNote] {
        notes.filter { $0.tags.contains(tag) }
    }
    
    var allTags: [String] {
        let tagSet = Set(notes.flatMap { $0.tags })
        return Array(tagSet).sorted()
    }
    
    var averageMood: SessionNote.Mood? {
        let moodNotes = notes.compactMap { $0.mood }
        guard !moodNotes.isEmpty else { return nil }
        
        // Simple average (could be more sophisticated)
        let moodValues: [SessionNote.Mood: Int] = [
            .great: 5,
            .good: 4,
            .okay: 3,
            .tired: 2,
            .frustrated: 1
        ]
        
        let total = moodNotes.compactMap { moodValues[$0] }.reduce(0, +)
        let average = Double(total) / Double(moodNotes.count)
        
        if average >= 4.5 { return .great }
        if average >= 3.5 { return .good }
        if average >= 2.5 { return .okay }
        if average >= 1.5 { return .tired }
        return .frustrated
    }
    
    // MARK: - Export
    
    func exportToMarkdown() -> String {
        var markdown = "# Focus Session Journal\n\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        
        for note in notes {
            markdown += "## \(dateFormatter.string(from: note.date))\n\n"
            
            if let mood = note.mood {
                markdown += "**Mood:** \(mood.rawValue) \(mood.description)\n\n"
            }
            
            markdown += "**Duration:** \(Int(note.sessionDuration / 60)) minutes\n"
            markdown += "**Cycles:** \(note.cyclesCompleted)\n\n"
            
            if let task = note.taskCompleted {
                markdown += "**Task:** \(task)\n\n"
            }
            
            if !note.tags.isEmpty {
                markdown += "**Tags:** \(note.tags.joined(separator: ", "))\n\n"
            }
            
            markdown += "**Notes:**\n\(note.note)\n\n"
            markdown += "---\n\n"
        }
        
        return markdown
    }
    
    // MARK: - Persistence
    
    private func saveNotes() {
        if let encoded = try? JSONEncoder().encode(notes) {
            defaults.set(encoded, forKey: notesKey)
        }
    }
    
    private func loadNotes() {
        if let data = defaults.data(forKey: notesKey),
           let decoded = try? JSONDecoder().decode([SessionNote].self, from: data) {
            notes = decoded
        }
    }
}

