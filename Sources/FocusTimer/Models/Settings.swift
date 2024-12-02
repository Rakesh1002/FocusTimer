import Foundation

class Settings: ObservableObject {
    @Published var workDuration: TimeInterval {
        didSet { saveSettings() }
    }
    
    @Published var breakDuration: TimeInterval {
        didSet { saveSettings() }
    }
    
    @Published var maxCycles: Int {
        didSet { saveSettings() }
    }
    
    @Published var showTimeDisplay: Bool {
        didSet { saveSettings() }
    }
    
    @Published var showBreakOverlay: Bool {
        didSet { saveSettings() }
    }
    
    @Published var breakNotifications: Bool {
        didSet { saveSettings() }
    }
    
    @Published var sessionCompleteNotifications: Bool {
        didSet { saveSettings() }
    }
    
    private let defaults = UserDefaults.standard
    
    init() {
        // Default to 50 minutes work duration
        self.workDuration = defaults.double(forKey: "workDuration").nonZero ?? 50 * 60
        self.breakDuration = defaults.double(forKey: "breakDuration").nonZero ?? 10 * 60
        self.maxCycles = defaults.integer(forKey: "maxCycles").nonZero ?? 4
        self.showTimeDisplay = defaults.bool(forKey: "showTimeDisplay")
        self.showBreakOverlay = defaults.bool(forKey: "showBreakOverlay")
        self.breakNotifications = defaults.bool(forKey: "breakNotifications")
        self.sessionCompleteNotifications = defaults.bool(forKey: "sessionCompleteNotifications")
    }
    
    // Make this public so it can be called from MenuBarView
    func saveSettings() {
        defaults.set(workDuration, forKey: "workDuration")
        defaults.set(breakDuration, forKey: "breakDuration")
        defaults.set(maxCycles, forKey: "maxCycles")
        defaults.set(showTimeDisplay, forKey: "showTimeDisplay")
        defaults.set(showBreakOverlay, forKey: "showBreakOverlay")
        defaults.set(breakNotifications, forKey: "breakNotifications")
        defaults.set(sessionCompleteNotifications, forKey: "sessionCompleteNotifications")
    }
}

extension Int {
    var nonZero: Int? {
        return self == 0 ? nil : self
    }
}

extension Double {
    var nonZero: Double? {
        return self == 0 ? nil : self
    }
}
