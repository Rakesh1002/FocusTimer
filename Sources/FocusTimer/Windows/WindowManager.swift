import SwiftUI
import AppKit

class WindowManager {
    static let shared = WindowManager()
    private var timeDisplayWindow: NSWindow?
    private var breakOverlayController: BreakOverlayWindowController?
    private var timerManager: TimerManager?
    
    private init() {}
    
    func showTimeDisplay() {
        if timeDisplayWindow == nil {
            let window = TimeOverlayWindow()
            timeDisplayWindow = window
            
            if let manager = timerManager {
                updateTimeDisplayView(window: window, manager: manager)
            }
            
            window.orderFront(nil)
        } else {
            timeDisplayWindow?.orderFront(nil)
        }
    }
    
    func hideTimeDisplay() {
        timeDisplayWindow?.orderOut(nil)
    }
    
    func setTimerManager(_ manager: TimerManager) {
        self.timerManager = manager
        
        if let window = timeDisplayWindow {
            updateTimeDisplayView(window: window, manager: manager)
        }
    }
    
    private func updateTimeDisplayView(window: NSWindow, manager: TimerManager) {
        let timeDisplayView = TimeDisplayWindow()
            .environmentObject(manager)
        window.contentView = NSHostingView(rootView: timeDisplayView)
    }
    
    func showBreakOverlay() {
        if breakOverlayController == nil {
            breakOverlayController = BreakOverlayWindowController()
        }
        breakOverlayController?.showWindow(nil)
    }
    
    func hideBreakOverlay() {
        breakOverlayController?.close()
        breakOverlayController = nil
    }
    
    func cleanup() {
        hideTimeDisplay()
        hideBreakOverlay()
    }
}
