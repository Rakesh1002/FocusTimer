import SwiftUI
import AppKit
import Combine
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var onboardingWindow: NSWindow?
    var showingOnboarding = false
    let settings = Settings()
    let timerManager: TimerManager
    let statisticsManager = StatisticsManager()
    let soundManager = SoundManager()
    let taskManager = TaskManager()
    let calendarManager = CalendarManager()
    let presetManager = PresetManager()
    let sessionJournal = SessionJournal()
    let breakActivityManager = BreakActivityManager()
    var eventMonitor: Any?
    private var eventMonitorGlobal: Any?
    private var isPerformingPopoverAction = false  // Prevent rapid open/close race conditions
    
    override init() {
        self.timerManager = TimerManager(settings: settings)
        super.init()
        
        // Connect managers
        self.timerManager.statisticsManager = statisticsManager
        self.timerManager.soundManager = soundManager
        self.timerManager.sessionJournal = sessionJournal
        self.timerManager.breakActivityManager = breakActivityManager
        self.timerManager.presetManager = presetManager
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Handle first launch and app updates
        AppSetupManager.shared.performFirstLaunchSetup()
        AppSetupManager.shared.handleAppUpdate()
        
        setupStatusItem()
        setupKeyboardShortcuts()
        WindowManager.shared.setSettings(settings)
        WindowManager.shared.setTimerManager(timerManager)
        
        // Hide the default SwiftUI window (we use menu bar + custom windows)
        hideDefaultWindow()
        
        // Show onboarding for first-time users
        if AppSetupManager.shared.shouldShowOnboarding {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.showOnboarding()
            }
        } else {
            // Show floating timer if enabled (with delay to ensure app is fully loaded)
            if settings.showTimeDisplay {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    NSLog("🚀 AppDelegate: Showing floating timer on launch")
                    WindowManager.shared.showTimeDisplay()
                }
            }
        }
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
        
        // Listen for notification to close popover
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(closePopover),
            name: NSNotification.Name("ClosePopover"),
            object: nil
        )

        // Toggle time display window from keyboard shortcut
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ToggleTimeDisplay"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            if self.settings.showTimeDisplay {
                WindowManager.shared.hideTimeDisplay()
                self.settings.showTimeDisplay = false
            } else {
                WindowManager.shared.showTimeDisplay()
                self.settings.showTimeDisplay = true
            }
        }
        
        // Open main popover when floating timer is clicked
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showPopover),
            name: NSNotification.Name("OpenMainPopover"),
            object: nil
        )
    }
    
    @objc func closePopover() {
        NSLog("🚪 Closing popover")
        
        // Prevent rapid toggling
        guard !isPerformingPopoverAction else {
            NSLog("⚠️ Popover action already in progress, skipping close")
            return
        }
        
        guard let popover = self.popover, popover.isShown else {
            NSLog("   Popover already closed or nil")
            return
        }
        
        isPerformingPopoverAction = true
        
        // Stop monitoring BEFORE closing to avoid re-triggering
        stopMonitoringPopover()
        
        // Close the popover
        popover.close()
        
        NSLog("✅ Popover closed")
        
        // Reset flag after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.isPerformingPopoverAction = false
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        if let eventMonitor = eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
        stopMonitoringPopover()
        KeyboardShortcutManager.shared.unregisterGlobalShortcuts()
        WindowManager.shared.cleanup()
    }
    
    // CRITICAL: Prevent app from quitting when floating timer window is closed
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        NSLog("🛡️ AppDelegate: Preventing quit on window close - this is a menu bar app!")
        return false  // Menu bar apps should NOT quit when windows close
    }
    
    func setupKeyboardShortcuts() {
        KeyboardShortcutManager.shared.timerManager = timerManager
        KeyboardShortcutManager.shared.registerGlobalShortcuts()
    }
    
    func setupEventMonitor() {
        // Click-outside monitoring is attached when the popover is shown
    }
    
    func setupStatusItem() {
        // Create the status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "timer", accessibilityDescription: "Timer")
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        // Create a custom panel instead of NSPopover for better control
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 400, height: 500)
        popover?.behavior = .applicationDefined
        popover?.animates = false  // ✅ Disable animation to hide arrow transition
        
        // Make the popover appear without an arrow by customizing its appearance
        // We'll position it manually to avoid the arrow
        
        // Create the SwiftUI view hierarchy
        let contentView = MenuBarView()
            .environmentObject(settings)
            .environmentObject(timerManager)
            .environmentObject(statisticsManager)
            .environmentObject(soundManager)
            .environmentObject(taskManager)
            .environmentObject(calendarManager)
            .environmentObject(presetManager)
            .environmentObject(sessionJournal)
            .environmentObject(breakActivityManager)
            .frame(minWidth: 400, maxWidth: 600)
        
        let hostingController = NSHostingController(rootView: contentView)
        
        // Force active appearance to show vibrant colors always
        hostingController.view.appearance = NSAppearance(named: .darkAqua)
        
        popover?.contentViewController = hostingController
        
        // Observe timer state changes to update icon
        timerManager.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateStatusBarIcon()
            }
        }.store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private func updateStatusBarIcon() {
        guard let button = statusItem?.button else { return }
        
        if timerManager.isRunning {
            if timerManager.isBreakTime {
                // Break time - coffee icon
                button.image = NSImage(systemSymbolName: "cup.and.saucer.fill", accessibilityDescription: "Break Time")
            } else {
                // Focus time - active timer
                button.image = NSImage(systemSymbolName: "timer.circle.fill", accessibilityDescription: "Focus Time")
            }
        } else {
            // Idle state
            button.image = NSImage(systemSymbolName: "timer", accessibilityDescription: "Timer")
        }
    }
    
    @objc func togglePopover() {
        guard statusItem?.button != nil, let popover = self.popover else { return }
        
        if popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }
    
    @objc func showPopover() {
        guard let button = statusItem?.button, let popover = self.popover else { return }
        
        // Prevent rapid toggling
        guard !isPerformingPopoverAction else { 
            NSLog("⚠️ Popover action already in progress, skipping")
            return 
        }
        
        // Don't show if already showing
        guard !popover.isShown else { return }
        
        isPerformingPopoverAction = true
        
        // Clean up any existing monitors
        stopMonitoringPopover()
        
        // Activate the app to ensure proper focus
        NSApp.activate(ignoringOtherApps: true)
        
        // ✅ Show popover with centered positioning to minimize arrow visibility
        // Position it directly below the button with no arrow edge preference
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        
        // CRITICAL: Use async to ensure window hierarchy is established
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let popover = self.popover else { 
                self?.isPerformingPopoverAction = false
                return 
            }
            
            // Make the popover window key and bring it to front
            if let popoverWindow = popover.contentViewController?.view.window {
                // ✅ Set dark background
                let customPurple = NSColor(red: 0.12, green: 0.08, blue: 0.28, alpha: 1.0)
                popoverWindow.backgroundColor = customPurple
                popoverWindow.appearance = NSAppearance(named: .darkAqua)
                popoverWindow.isOpaque = false
                popoverWindow.hasShadow = true
                
                // ✅ Find and hide just the arrow by iterating through subviews
                if let borderView = popoverWindow.contentView?.superview {
                    // The arrow is typically the first or last sublayer
                    // We'll hide it by making it transparent
                    for subview in borderView.subviews {
                        // The content view is the one we want to keep
                        if subview != popoverWindow.contentView {
                            // This is likely the arrow or border chrome
                            subview.wantsLayer = true
                            subview.layer?.backgroundColor = customPurple.cgColor
                            subview.layer?.opacity = 0.0  // Hide the arrow
                        }
                    }
                }
                
                popoverWindow.makeKey()
                popoverWindow.orderFrontRegardless()
                NSLog("🪟 Popover displayed with arrow hidden")
            }
            
            // Start monitoring for outside clicks
            self.startMonitoringPopover()
            
            // Reset flag after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.isPerformingPopoverAction = false
            }
        }
    }
    
    // MARK: - Popover Click-Outside Monitoring
    private func startMonitoringPopover() {
        // Clean up first
        stopMonitoringPopover()
        
        // Only use GLOBAL monitor - no local monitor to avoid interference
        eventMonitorGlobal = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, let popover = self.popover, popover.isShown else { return }
            
            // Get the popover window frame
            guard let popoverWindow = popover.contentViewController?.view.window else {
                self.closePopover()
                return
            }
            
            // Check if click is outside the popover
            let mouseLocation = NSEvent.mouseLocation
            if !popoverWindow.frame.contains(mouseLocation) {
                self.closePopover()
            }
        }
    }

    private func stopMonitoringPopover() {
        if let monitor = eventMonitorGlobal {
            NSEvent.removeMonitor(monitor)
            eventMonitorGlobal = nil
        }
        // Note: We no longer use local monitor as it interferes with popover interaction
    }
    
    // MARK: - Onboarding
    
    func showOnboarding() {
        showingOnboarding = true
        
        // Create onboarding view with proper binding
        let onboardingView = OnboardingView(
            isPresented: Binding(
                get: { 
                    print("📖 Binding GET: showingOnboarding = \(self.showingOnboarding)")
                    return self.showingOnboarding 
                },
                set: { newValue in
                    print("📝 Binding SET: newValue = \(newValue)")
                    self.showingOnboarding = newValue
                    if !newValue {
                        print("📝 Binding: Calling dismissOnboarding()")
                        self.dismissOnboarding()
                    }
                }
            )
        )
        .environmentObject(settings)
        .environmentObject(calendarManager)
        
        let hostingController = NSHostingController(rootView: onboardingView)
        
        // Create window for onboarding
        onboardingWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 700),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        onboardingWindow?.title = "Welcome to Focusly"
        onboardingWindow?.contentViewController = hostingController
        onboardingWindow?.center()
        onboardingWindow?.isReleasedWhenClosed = false
        onboardingWindow?.titlebarAppearsTransparent = true
        onboardingWindow?.titleVisibility = .hidden
        
        // Handle window close button
        onboardingWindow?.delegate = self
        
        onboardingWindow?.makeKeyAndOrderFront(nil)
        
        NSApp.activate(ignoringOtherApps: true)
        
        print("👋 Showing onboarding")
    }
    
    private func hideDefaultWindow() {
        // Hide the default SwiftUI WindowGroup window
        DispatchQueue.main.async {
            if let window = NSApp.windows.first(where: { $0.contentViewController is NSHostingController<MinimalView> }) {
                window.orderOut(nil)
                window.setIsVisible(false)
                print("🙈 Hidden default SwiftUI window")
            }
        }
    }
    
    private func dismissOnboarding() {
        guard showingOnboarding else { 
            print("⚠️ dismissOnboarding: already dismissed")
            return
        }
        
        print("👋 Dismissing onboarding")
        
        showingOnboarding = false
        
        // Close window without triggering delegate again
        let windowToClose = onboardingWindow
        onboardingWindow = nil
        windowToClose?.close()
        
        print("✅ Onboarding window closed")
        
        // Show floating timer after onboarding if enabled
        if settings.showTimeDisplay {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                print("🚀 AppDelegate: Showing floating timer after onboarding")
                WindowManager.shared.showTimeDisplay()
            }
        }
    }
    
    // Clean up observers and monitors
    deinit {
        NotificationCenter.default.removeObserver(self)
        stopMonitoringPopover()
        cancellables.removeAll()
    }
}

// MARK: - NSWindowDelegate
extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        // Handle onboarding window close
        if let window = notification.object as? NSWindow, window == onboardingWindow {
            print("👋 Onboarding window closed via close button")
            // Only dismiss if still showing (prevent recursion)
            if showingOnboarding {
                dismissOnboarding()
            }
        }
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // Allow onboarding window to close
        print("🚪 windowShouldClose called for: \(sender)")
        return true
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
struct FocuslyApp: App {
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
