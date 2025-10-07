import SwiftUI
import AppKit

class TimeOverlayWindow: NSWindow {
    init(screen: NSScreen = NSScreen.main ?? NSScreen.screens[0]) {
        // Calculate position on the specified screen
        let screenFrame = screen.visibleFrame
        let windowWidth: CGFloat = 120
        let windowHeight: CGFloat = 40
        let windowX = screenFrame.maxX - windowWidth - 20
        let windowY = screenFrame.maxY - windowHeight - 20
        
        // Initialize with position on the specified screen
        super.init(
            contentRect: NSRect(x: windowX, y: windowY, width: windowWidth, height: windowHeight),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        self.backgroundColor = .clear
        self.isOpaque = false
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces]
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden
        self.isMovableByWindowBackground = true
        self.ignoresMouseEvents = false
    }
}

class TimeDisplayWindowController: NSWindowController {
    convenience init() {
        let window = TimeOverlayWindow()
        window.title = "Focus Timer"
        window.center()
        window.isMovableByWindowBackground = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        self.init(window: window)
    }
}

struct TimeDisplayWindow: View {
    @EnvironmentObject var timerManager: TimerManager
    @State private var currentTime = Date()
    @State private var previousRunningState = false
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            // Current time
            Text(timeString(from: currentTime))
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
            
            // Countdown timer (if running)
            if timerManager.isRunning {
                Text(formatTime(timerManager.remainingTime))
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundColor(timerManager.isBreakTime ? .mint : .orange)
            }
        }
        .padding(8)
        .frame(width: 120)
        .background(Color.black.opacity(0.75))
        .cornerRadius(8)
        .contentShape(Rectangle())
        .onTapGesture {
            // Open the main app popover when clicked
            NotificationCenter.default.post(name: NSNotification.Name("OpenMainPopover"), object: nil)
        }
        .onReceive(timer) { time in
            currentTime = time
        }
        .onChange(of: timerManager.isRunning) { isRunning in
            // Only resize window when running state changes, not every second
            if previousRunningState != isRunning {
                if let window = NSApp.windows.first(where: { $0 is TimeOverlayWindow }) {
                    let newHeight: CGFloat = isRunning ? 70 : 40
                    var frame = window.frame
                    frame.origin.y += frame.height - newHeight
                    frame.size.height = newHeight
                    window.setFrame(frame, display: true, animate: false)
                }
                previousRunningState = isRunning
            }
        }
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

class TimerPublisher: ObservableObject {
    @Published var currentTimeString: String = ""
    private var timer: Timer?
    private let formatter: DateFormatter
    
    init() {
        formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        updateTime()
        startTimer()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateTime()
        }
    }
    
    private func updateTime() {
        currentTimeString = formatter.string(from: Date())
    }
    
    deinit {
        timer?.invalidate()
    }
}
