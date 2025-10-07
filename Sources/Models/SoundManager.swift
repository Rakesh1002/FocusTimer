import AVFoundation
import AppKit

enum SoundType: String, CaseIterable, Codable {
    case none = "None"
    case workComplete = "Work Complete (Hero)"
    case breakTime = "Break Time (Glass)"
    case sessionComplete = "Session Complete (Sosumi)"
    case gentle = "Gentle (Tink)"
    case notification = "Notification (Ping)"
    case celebration = "Celebration (Funk)"
    
    var systemSoundName: String? {
        switch self {
        case .none:
            return nil
        case .workComplete:
            return "Hero" // Clear completion sound
        case .breakTime:
            return "Glass" // Relaxing break sound
        case .sessionComplete:
            return "Sosumi" // Achievement sound
        case .gentle:
            return "Tink" // Subtle notification
        case .notification:
            return "Ping" // Clear alert
        case .celebration:
            return "Funk" // Full session completion
        }
    }
}

class SoundManager: ObservableObject {
    @Published var isEnabled: Bool {
        didSet { saveSettings() }
    }
    
    @Published var workCompleteSound: SoundType {
        didSet { saveSettings() }
    }
    
    @Published var breakCompleteSound: SoundType {
        didSet { saveSettings() }
    }
    
    @Published var sessionCompleteSound: SoundType {
        didSet { saveSettings() }
    }
    
    @Published var volume: Float {
        didSet { saveSettings() }
    }
    
    private var audioPlayer: AVAudioPlayer?
    private let defaults = UserDefaults.app
    
    init() {
        // Enable sounds by default if key not present
        if defaults.object(forKey: "soundEnabled") == nil {
            defaults.set(true, forKey: "soundEnabled")
        }
        self.isEnabled = defaults.bool(forKey: "soundEnabled")
        self.volume = defaults.float(forKey: "soundVolume").nonZero ?? 0.5
        
        if let workSoundRaw = defaults.string(forKey: "workCompleteSound"),
           let workSound = SoundType(rawValue: workSoundRaw) {
            self.workCompleteSound = workSound
        } else {
            self.workCompleteSound = .workComplete
        }
        
        if let breakSoundRaw = defaults.string(forKey: "breakCompleteSound"),
           let breakSound = SoundType(rawValue: breakSoundRaw) {
            self.breakCompleteSound = breakSound
        } else {
            self.breakCompleteSound = .breakTime
        }
        
        if let sessionSoundRaw = defaults.string(forKey: "sessionCompleteSound"),
           let sessionSound = SoundType(rawValue: sessionSoundRaw) {
            self.sessionCompleteSound = sessionSound
        } else {
            self.sessionCompleteSound = .celebration
        }
    }
    
    // MARK: - Play Sounds
    
    func playWorkCompleteSound() {
        guard isEnabled else { return }
        playSound(workCompleteSound)
    }
    
    func playBreakCompleteSound() {
        guard isEnabled else { return }
        playSound(breakCompleteSound)
    }
    
    func playSessionCompleteSound() {
        guard isEnabled else { return }
        playSound(sessionCompleteSound)
    }
    
    private func playSound(_ soundType: SoundType) {
        guard soundType != .none,
              let soundName = soundType.systemSoundName else { return }
        
        // Play system sound using NSSound
        if let sound = NSSound(named: soundName) {
            sound.volume = volume
            sound.play()
        }
    }
    
    // MARK: - Preview Sound
    
    func previewSound(_ soundType: SoundType) {
        playSound(soundType)
    }
    
    // MARK: - Persistence
    
    private func saveSettings() {
        defaults.set(isEnabled, forKey: "soundEnabled")
        defaults.set(volume, forKey: "soundVolume")
        defaults.set(workCompleteSound.rawValue, forKey: "workCompleteSound")
        defaults.set(breakCompleteSound.rawValue, forKey: "breakCompleteSound")
        defaults.set(sessionCompleteSound.rawValue, forKey: "sessionCompleteSound")
    }
}

extension Float {
    var nonZero: Float? {
        return self == 0 ? nil : self
    }
}

