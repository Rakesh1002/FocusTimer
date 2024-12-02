import AppKit
import UserNotifications
import AVFoundation

@MainActor
class PermissionManager: ObservableObject {
    static let shared = PermissionManager()
    
    @Published private(set) var hasScreenRecordingPermission = false
    @Published private(set) var hasNotificationPermission = false
    @Published private(set) var hasAccessibilityPermission = false
    
    private init() {
        checkInitialPermissions()
    }
    
    private func checkInitialPermissions() {
        // Check Screen Recording permission
        hasScreenRecordingPermission = CGPreflightScreenCaptureAccess()
        
        // Check Accessibility permission
        hasAccessibilityPermission = AXIsProcessTrusted()
    }
    
    func requestPermissions() {
        requestScreenRecordingPermission()
        requestAccessibilityPermission()
        // Notification permissions will be requested by TimerManager
    }
    
    private func requestScreenRecordingPermission() {
        if !hasScreenRecordingPermission {
            // This will prompt the user for screen recording permission
            CGRequestScreenCaptureAccess()
            
            // Show instructions if needed
            let alert = NSAlert()
            alert.messageText = "Screen Recording Permission Required"
            alert.informativeText = "Please grant screen recording permission in System Preferences > Security & Privacy > Privacy > Screen Recording"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open System Preferences")
            alert.addButton(withTitle: "Later")
            
            if alert.runModal() == .alertFirstButtonReturn {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
    
    private func requestAccessibilityPermission() {
        if !hasAccessibilityPermission {
            let alert = NSAlert()
            alert.messageText = "Accessibility Permission Required"
            alert.informativeText = "Please grant accessibility permission in System Preferences > Security & Privacy > Privacy > Accessibility"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open System Preferences")
            alert.addButton(withTitle: "Later")
            
            if alert.runModal() == .alertFirstButtonReturn {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
}
