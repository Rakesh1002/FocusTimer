import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    let settings = Settings()
    let timerManager: TimerManager
    var eventMonitor: Any?
    
    override init() {
        self.timerManager = TimerManager(settings: settings)
        super.init()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        WindowManager.shared.setTimerManager(timerManager)
        WindowManager.shared.showTimeDisplay()
        setupEventMonitor()
        
        // Prevent showing dock icon
        NSApp.setActivationPolicy(.accessory)
        
        // Hide only the main app window, not our custom overlay
        NSApp.windows.forEach { window in
            if !(window is TimeOverlayWindow) {
                window.setIsVisible(false)
                window.orderOut(nil)
            }
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        if let eventMonitor = eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
        WindowManager.shared.cleanup()
    }
    
    func setupEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if let popover = self?.popover, popover.isShown {
                popover.performClose(nil)
            }
        }
    }
    
    func setupStatusItem() {
        // Create the status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "timer", accessibilityDescription: "Timer")
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        // Create the popover
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 400, height: 500)
        popover?.behavior = .transient
        
        // Create the SwiftUI view hierarchy
        let contentView = MenuBarView()
            .environmentObject(settings)
            .environmentObject(timerManager)
            .frame(minWidth: 350, maxWidth: 400)
        
        popover?.contentViewController = NSHostingController(rootView: contentView)
    }
    
    @objc func togglePopover() {
        if let button = statusItem?.button {
            if let popover = self.popover {
                if popover.isShown {
                    popover.performClose(nil)
                } else {
                    popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
                }
            }
        }
    }
}

struct MinimalView: View {
    var body: some View {
        EmptyView()
            .frame(maxWidth: 0, maxHeight: 0)
            .background(.clear)
    }
}

@main
struct FocusTimerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            MinimalView()
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 0, height: 0)
    }
}
