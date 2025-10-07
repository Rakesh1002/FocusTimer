import AppKit
import Carbon

class KeyboardShortcutManager {
    static let shared = KeyboardShortcutManager()
    
    // Local foreground-only monitor (fallback)
    private var localEventMonitor: Any?
    // Carbon global hotkeys
    private var carbonEventHandler: EventHandlerRef?
    private var hotKeyRefs: [EventHotKeyRef] = []
    weak var timerManager: TimerManager?
    
    private init() {}
    
    func registerGlobalShortcuts() {
        // Try to register Carbon global hotkeys first
        if !registerCarbonHotKeys() {
            // Fallback to foreground-only local monitor
            localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                return self?.handleKeyEvent(event) ?? event
            }
        }
    }
    
    func unregisterGlobalShortcuts() {
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }
        // Unregister Carbon hotkeys
        for ref in hotKeyRefs {
            UnregisterEventHotKey(ref)
        }
        hotKeyRefs.removeAll()
        if let handler = carbonEventHandler {
            RemoveEventHandler(handler)
            carbonEventHandler = nil
        }
    }
    
    private func handleKeyEvent(_ event: NSEvent) -> NSEvent? {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        
        // Check for Command+Option combinations
        if modifiers.contains([.command, .option]) {
            switch event.charactersIgnoringModifiers {
            case "t", "T": // ⌘⌥T - Start/Stop timer
                toggleTimer()
                return nil
                
            case "r", "R": // ⌘⌥R - Reset timer
                resetTimer()
                return nil
                
            case "s", "S": // ⌘⌥S - Skip break
                skipBreak()
                return nil
                
            case "b", "B": // ⌘⌥B - Toggle time display
                toggleTimeDisplay()
                return nil
                
            case ",": // ⌘⌥, - Open settings (already handled by system)
                break
                
            default:
                break
            }
        }
        
        return event
    }
    
    // MARK: - Carbon global hotkeys
    private func registerCarbonHotKeys() -> Bool {
        // Install handler for hotkey pressed
        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        let status = InstallEventHandler(GetEventDispatcherTarget(), { (nextHandler, theEvent, userData) -> OSStatus in
            guard let userData = userData else { return noErr }
            let manager = Unmanaged<KeyboardShortcutManager>.fromOpaque(userData).takeUnretainedValue()
            var hotKeyID = EventHotKeyID()
            let err = GetEventParameter(theEvent,
                                        EventParamName(kEventParamDirectObject),
                                        EventParamType(typeEventHotKeyID),
                                        nil,
                                        MemoryLayout<EventHotKeyID>.size,
                                        nil,
                                        &hotKeyID)
            if err == noErr {
                manager.handleHotKeyID(hotKeyID.id)
            }
            return noErr
        }, 1, &eventSpec, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()), &carbonEventHandler)
        if status != noErr { return false }
        
        // Helper to register a hotkey
        func register(_ keyCode: UInt32, _ modifiers: UInt32, _ id: UInt32) -> Bool {
            var ref: EventHotKeyRef?
            let hotKeyID = EventHotKeyID(signature: OSType(0x46544D52), id: id) // 'FTMR'
            let err = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetEventDispatcherTarget(), 0, &ref)
            if err == noErr, let ref = ref { hotKeyRefs.append(ref); return true }
            return false
        }
        
        let mods = UInt32(cmdKey) | UInt32(optionKey)
        var ok = true
        // ⌘⌥T
        ok = register(UInt32(kVK_ANSI_T), mods, 1) && ok
        // ⌘⌥R
        ok = register(UInt32(kVK_ANSI_R), mods, 2) && ok
        // ⌘⌥S
        ok = register(UInt32(kVK_ANSI_S), mods, 3) && ok
        // ⌘⌥B
        ok = register(UInt32(kVK_ANSI_B), mods, 4) && ok
        
        return ok
    }
    
    private func handleHotKeyID(_ id: UInt32) {
        switch id {
        case 1: toggleTimer()
        case 2: resetTimer()
        case 3: skipBreak()
        case 4: toggleTimeDisplay()
        default: break
        }
    }
    
    // MARK: - Actions
    
    private func toggleTimer() {
        guard let timerManager = timerManager else { return }
        
        if timerManager.isRunning {
            timerManager.stop()
        } else {
            timerManager.start()
        }
    }
    
    private func resetTimer() {
        guard let timerManager = timerManager else { return }
        
        timerManager.stop()
        // Timer will reset automatically when stopped
    }
    
    private func skipBreak() {
        guard let timerManager = timerManager,
              timerManager.isBreakTime else { return }
        
        timerManager.skipBreakStartWork()
    }
    
    private func toggleTimeDisplay() {
        // Toggle the time display window visibility
        NotificationCenter.default.post(name: NSNotification.Name("ToggleTimeDisplay"), object: nil)
    }
}

