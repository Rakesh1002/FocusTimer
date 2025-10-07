import SwiftUI
import AppKit

class WindowManager {
    static let shared = WindowManager()
    private var timeDisplayWindows: [NSWindow] = []
    private var breakOverlayController: BreakOverlayWindowController?
    private var timerManager: TimerManager?
    private var settings: Settings?
    private var isShowingWindows = false  // Prevent concurrent calls
    
    private init() {
        // Listen for screen configuration changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }
    
    func setSettings(_ settings: Settings) {
        self.settings = settings
    }
    
    @objc private func screensDidChange() {
        // Refresh windows when screen configuration changes
        if !timeDisplayWindows.isEmpty {
            hideTimeDisplay()
            showTimeDisplay()
        }
    }
    
    func showTimeDisplay() {
        NSLog("📞 WindowManager: showTimeDisplay() called, current thread: \(Thread.isMainThread ? "main" : "background")")
        
        // Ensure we're on main thread
        guard Thread.isMainThread else {
            NSLog("⚡ WindowManager: Dispatching to main thread")
            DispatchQueue.main.async { [weak self] in
                self?.showTimeDisplay()
            }
            return
        }
        
        // Prevent concurrent calls
        guard !isShowingWindows else {
            NSLog("⚠️ WindowManager: Already showing windows, skipping")
            return
        }
        
        isShowingWindows = true
        defer { 
            isShowingWindows = false
            NSLog("🔓 WindowManager: isShowingWindows flag reset")
        }
        
        NSLog("🖥️ WindowManager: Showing floating timer windows")
        NSLog("   Settings showTimeDisplay: \(settings?.showTimeDisplay ?? false)")
        NSLog("   Settings showOnAllScreens: \(settings?.showFloatingTimerOnAllScreens ?? false)")
        
        // If windows already exist, simply bring them to front and refresh content
        if !timeDisplayWindows.isEmpty {
            NSLog("🔁 WindowManager: Reusing \(timeDisplayWindows.count) existing window(s)")
            for window in timeDisplayWindows {
                if let manager = timerManager {
                    updateTimeDisplayView(window: window, manager: manager)
                }
                window.orderFrontRegardless()
            }
            NSLog("✅ WindowManager: Reused existing windows")
            return
        }
        
        let screens = settings?.showFloatingTimerOnAllScreens == true ? NSScreen.screens : [NSScreen.main].compactMap { $0 }
        
        guard !screens.isEmpty else {
            NSLog("❌ WindowManager: No screens available!")
            return
        }
        
        NSLog("📱 WindowManager: Creating windows for \(screens.count) screen(s)")
        
        for screen in screens {
            NSLog("   Creating window for: \(screen.localizedName)")
            let window = TimeOverlayWindow(screen: screen)
            
            if let manager = timerManager {
                updateTimeDisplayView(window: window, manager: manager)
            } else {
                NSLog("   ⚠️ No timer manager available")
            }
            
            // Ensure window is visible and at the correct level
            window.orderFrontRegardless()
            
            timeDisplayWindows.append(window)
            NSLog("   ✅ Window created and ordered front")
        }
        
        NSLog("✅ WindowManager: \(timeDisplayWindows.count) windows active")
    }
    
    func hideTimeDisplay() {
        NSLog("📞 WindowManager: hideTimeDisplay() called, current thread: \(Thread.isMainThread ? "main" : "background")")
        
        // Ensure we're on main thread
        guard Thread.isMainThread else {
            NSLog("⚡ WindowManager: Dispatching hide to main thread")
            DispatchQueue.main.async { [weak self] in
                self?.hideTimeDisplay()
            }
            return
        }
        
        NSLog("🚫 WindowManager: Hiding \(timeDisplayWindows.count) floating timer window(s)")
        
        guard !timeDisplayWindows.isEmpty else {
            NSLog("   ℹ️ No windows to hide")
            return
        }
        
        // Just order out windows; keep them alive to avoid deallocation races
        for (index, window) in timeDisplayWindows.enumerated() {
            NSLog("   👻 Ordering out window \(index + 1)/\(timeDisplayWindows.count)")
            window.orderOut(nil)
        }
        
        NSLog("✅ WindowManager: All windows ordered out (hidden)")
    }
    
    func setTimerManager(_ manager: TimerManager) {
        self.timerManager = manager
        
        for window in timeDisplayWindows {
            updateTimeDisplayView(window: window, manager: manager)
        }
    }
    
    private func updateTimeDisplayView(window: NSWindow, manager: TimerManager) {
        let timeDisplayView = TimeDisplayWindow()
            .environmentObject(manager)
        window.contentView = NSHostingView(rootView: timeDisplayView)
    }
    
    func showBreakOverlay() {
        NSLog("🔔 WindowManager: showBreakOverlay() called")
        
        guard let timerManager = timerManager else {
            NSLog("⚠️ WindowManager: Cannot show break overlay - timerManager is nil")
            return
        }
        
        if breakOverlayController == nil {
            NSLog("🔔 WindowManager: Creating new break overlay controller")
            breakOverlayController = BreakOverlayWindowController(timerManager: timerManager)
        }
        
        NSLog("🔔 WindowManager: Calling show() on break overlay")
        breakOverlayController?.show()
    }
    
    func hideBreakOverlay() {
        NSLog("🔔 WindowManager: hideBreakOverlay() called")
        breakOverlayController?.hide()
        breakOverlayController?.close()
        breakOverlayController = nil
    }
    
    func cleanup() {
        hideTimeDisplay()
        hideBreakOverlay()
    }
}
