import SwiftUI
import AppKit

struct BreakOverlayView: View {
    @EnvironmentObject var timerManager: TimerManager
    @Environment(\.dismiss) var dismiss
    
    private var formattedTime: String {
        let minutes = Int(timerManager.remainingTime) / 60
        let seconds = Int(timerManager.remainingTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private var breakMessage: String {
        let totalMinutes = Int(timerManager.remainingTime / 60)
        let totalSeconds = Int(timerManager.remainingTime) % 60
        
        if totalMinutes > 0 {
            return "Take a \(totalMinutes) minute break"
        } else if totalSeconds > 0 {
            return "Take a short break"
        } else {
            return "Break ending..."
        }
    }
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Break Time!")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.white)
            
            Text(breakMessage)
                .font(.title2)
                .foregroundColor(.white.opacity(0.9))
            
            // Countdown Timer Display
            Text(formattedTime)
                .font(.system(size: 72, weight: .medium, design: .rounded))
                .foregroundColor(Color(red: 0.65, green: 0.55, blue: 1.0))
                .monospacedDigit()
            
            Spacer()
                .frame(height: 40)
            
            Button("Skip Break") {
                timerManager.stop()
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(Color(red: 0.65, green: 0.55, blue: 1.0))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.85))
    }
}

class BreakOverlayWindowController: NSWindowController {
    private var timerManager: TimerManager?
    
    convenience init(timerManager: TimerManager) {
        let window = NSWindow(
            contentRect: NSScreen.main?.frame ?? .zero,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        // Use popUpMenu level so it appears above normal windows but below floating timer (.floating)
        window.level = .popUpMenu
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        self.init(window: window)
        self.timerManager = timerManager
        
        // Set up the SwiftUI content view
        let contentView = BreakOverlayView()
            .environmentObject(timerManager)
        window.contentView = NSHostingView(rootView: contentView)
        
        NSLog("🔔 BreakOverlayWindow: Initialized with content view")
    }
    
    func show() {
        NSLog("🔔 BreakOverlayWindow: show() called")
        
        // Make window visible on all screens
        guard let mainScreen = NSScreen.main else {
            NSLog("⚠️ BreakOverlayWindow: No main screen found")
            return
        }
        
        window?.setFrame(mainScreen.frame, display: true)
        window?.makeKeyAndOrderFront(nil)
        window?.orderFrontRegardless()
        
        NSLog("🔔 BreakOverlayWindow: Window shown on main screen - frame: \(mainScreen.frame)")
        
        // Also cover other screens if multiple monitors
        if NSScreen.screens.count > 1 {
            NSLog("🔔 BreakOverlayWindow: Multiple screens detected: \(NSScreen.screens.count)")
        }
    }
    
    func hide() {
        NSLog("🔔 BreakOverlayWindow: hide() called")
        window?.orderOut(nil)
    }
}
