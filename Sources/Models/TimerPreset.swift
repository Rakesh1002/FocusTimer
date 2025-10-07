import Foundation

struct TimerPreset: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var workDuration: TimeInterval
    var breakDuration: TimeInterval
    var longBreakDuration: TimeInterval?
    var maxCycles: Int
    var icon: String
    var color: String
    var isBuiltIn: Bool
    
    init(
        id: UUID = UUID(),
        name: String,
        workDuration: TimeInterval,
        breakDuration: TimeInterval,
        longBreakDuration: TimeInterval? = nil,
        maxCycles: Int,
        icon: String = "timer",
        color: String = "blue",
        isBuiltIn: Bool = false
    ) {
        self.id = id
        self.name = name
        self.workDuration = workDuration
        self.breakDuration = breakDuration
        self.longBreakDuration = longBreakDuration
        self.maxCycles = maxCycles
        self.icon = icon
        self.color = color
        self.isBuiltIn = isBuiltIn
    }
    
    var workMinutes: Int {
        Int(workDuration / 60)
    }
    
    var breakMinutes: Int {
        Int(breakDuration / 60)
    }
    
    var description: String {
        "\(workMinutes)m work / \(breakMinutes)m break × \(maxCycles)"
    }
    
    // Built-in presets
    static let classicPomodoro = TimerPreset(
        name: "Classic Pomodoro",
        workDuration: 25 * 60,
        breakDuration: 5 * 60,
        longBreakDuration: 15 * 60,
        maxCycles: 4,
        icon: "timer",
        color: "red",
        isBuiltIn: true
    )
    
    static let deepWork = TimerPreset(
        name: "Deep Work",
        workDuration: 50 * 60,
        breakDuration: 10 * 60,
        longBreakDuration: 20 * 60,
        maxCycles: 4,
        icon: "brain.head.profile",
        color: "purple",
        isBuiltIn: true
    )
    
    static let ultraFocus = TimerPreset(
        name: "Ultra Focus",
        workDuration: 90 * 60,
        breakDuration: 15 * 60,
        longBreakDuration: 30 * 60,
        maxCycles: 3,
        icon: "flame.fill",
        color: "orange",
        isBuiltIn: true
    )
    
    static let shortSprint = TimerPreset(
        name: "Short Sprint",
        workDuration: 15 * 60,
        breakDuration: 3 * 60,
        longBreakDuration: 10 * 60,
        maxCycles: 6,
        icon: "hare.fill",
        color: "green",
        isBuiltIn: true
    )
    
    static let studySession = TimerPreset(
        name: "Study Session",
        workDuration: 45 * 60,
        breakDuration: 10 * 60,
        longBreakDuration: 20 * 60,
        maxCycles: 4,
        icon: "book.fill",
        color: "blue",
        isBuiltIn: true
    )
    
    static let longBreak = TimerPreset(
        name: "Long Break",
        workDuration: 30 * 60,
        breakDuration: 15 * 60,
        longBreakDuration: 30 * 60,
        maxCycles: 3,
        icon: "moon.stars.fill",
        color: "purple",
        isBuiltIn: true
    )
    
    static let creative = TimerPreset(
        name: "Creative Flow",
        workDuration: 60 * 60,
        breakDuration: 12 * 60,
        longBreakDuration: 25 * 60,
        maxCycles: 3,
        icon: "paintbrush.fill",
        color: "pink",
        isBuiltIn: true
    )
    
    static let quickBursts = TimerPreset(
        name: "Quick Bursts",
        workDuration: 10 * 60,
        breakDuration: 2 * 60,
        longBreakDuration: 5 * 60,
        maxCycles: 8,
        icon: "bolt.fill",
        color: "yellow",
        isBuiltIn: true
    )
    
    static let builtInPresets: [TimerPreset] = [
        .classicPomodoro,
        .deepWork,
        .ultraFocus,
        .shortSprint,
        .studySession,
        .longBreak,
        .creative,
        .quickBursts
    ]
}

class PresetManager: ObservableObject {
    @Published var presets: [TimerPreset] = []
    @Published var currentPreset: TimerPreset
    
    private let defaults = UserDefaults.app
    private let presetsKey = "timerPresets"
    private let currentPresetKey = "currentPresetId"
    
    init() {
        // Load custom presets
        var loadedPresets: [TimerPreset] = []
        if let data = defaults.data(forKey: presetsKey),
           let decoded = try? JSONDecoder().decode([TimerPreset].self, from: data) {
            loadedPresets = decoded
        }
        
        // Add built-in presets if not already present
        for builtIn in TimerPreset.builtInPresets {
            if !loadedPresets.contains(where: { $0.id == builtIn.id }) {
                loadedPresets.append(builtIn)
            }
        }
        
        // Initialize presets
        self.presets = loadedPresets
        
        // Load current preset
        if let currentId = defaults.string(forKey: currentPresetKey),
           let uuid = UUID(uuidString: currentId),
           let preset = loadedPresets.first(where: { $0.id == uuid }) {
            self.currentPreset = preset
        } else {
            self.currentPreset = TimerPreset.deepWork
        }
    }
    
    func addPreset(_ preset: TimerPreset) {
        presets.append(preset)
        savePresets()
    }
    
    func updatePreset(_ preset: TimerPreset) {
        if let index = presets.firstIndex(where: { $0.id == preset.id }) {
            presets[index] = preset
            savePresets()
            
            if currentPreset.id == preset.id {
                currentPreset = preset
                saveCurrentPreset()
            }
        }
    }
    
    func deletePreset(_ preset: TimerPreset) {
        guard !preset.isBuiltIn else { return }
        presets.removeAll { $0.id == preset.id }
        savePresets()
        
        if currentPreset.id == preset.id {
            setCurrentPreset(TimerPreset.deepWork)
        }
    }
    
    func setCurrentPreset(_ preset: TimerPreset) {
        currentPreset = preset
        saveCurrentPreset()
    }
    
    var customPresets: [TimerPreset] {
        presets.filter { !$0.isBuiltIn }
    }
    
    var builtInPresets: [TimerPreset] {
        presets.filter { $0.isBuiltIn }
    }
    
    private func savePresets() {
        // Only save custom presets
        let customPresets = presets.filter { !$0.isBuiltIn }
        if let encoded = try? JSONEncoder().encode(customPresets) {
            defaults.set(encoded, forKey: presetsKey)
        }
    }
    
    private func saveCurrentPreset() {
        defaults.set(currentPreset.id.uuidString, forKey: currentPresetKey)
    }
}

