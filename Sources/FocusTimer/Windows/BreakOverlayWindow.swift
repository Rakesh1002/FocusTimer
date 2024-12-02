import SwiftUI
import AppKit

struct BreakOverlayView: View {
    @EnvironmentObject var timerManager: TimerManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Break Time!")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
            
            Text("Take a \(Int(timerManager.remainingTime / 60)) minute break")
                .font(.title2)
                .foregroundColor(.white)
            
            Button("Skip Break") {
                timerManager.stop()
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.85))
    }
}

class BreakOverlayWindowController: NSWindowController {
    convenience init() {
        let window = NSWindow(
            contentRect: NSScreen.main?.frame ?? .zero,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window.level = .modalPanel
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        self.init(window: window)
    }
    
    func show() {
        window?.makeKeyAndOrderFront(nil)
        
        // Ensure window covers all screens
        NSScreen.screens.forEach { screen in
            window?.setFrame(screen.frame, display: true)
        }
    }
    
    func hide() {
        window?.orderOut(nil)
    }
}
