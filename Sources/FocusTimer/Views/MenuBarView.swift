import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var timerManager: TimerManager
    @State private var showingSettings = false
    
    var body: some View {
        VStack(spacing: 0) {
            if showingSettings {
                SettingsView(isPresented: $showingSettings)
            } else {
                mainView
            }
            
            Divider()
            
            // Bottom buttons
            HStack {
                if showingSettings {
                    Button("Done") {
                        settings.saveSettings()
                        showingSettings = false
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Settings") {
                        showingSettings = true
                    }
                }
                
                Spacer()
                
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .foregroundColor(.red)
            }
            .padding()
        }
    }
    
    private var mainView: some View {
        VStack(spacing: 20) {
            Text(timerManager.isBreakTime ? "Break Time!" : "Focus Time")
                .font(.title)
                .padding(.top)
            
            Text(formatTime(timerManager.remainingTime))
                .font(.system(size: 48, weight: .bold, design: .monospaced))
            
            HStack(spacing: 20) {
                Button(timerManager.isRunning ? "Stop" : "Start") {
                    if timerManager.isRunning {
                        timerManager.stop()
                    } else {
                        timerManager.start()
                    }
                }
                .buttonStyle(.borderedProminent)
                
                if timerManager.isBreakTime {
                    Button("Skip Break") {
                        timerManager.stop()
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            Text("Cycle \(timerManager.currentCycle)/\(settings.maxCycles)")
                .foregroundColor(.secondary)
                .padding(.bottom)
        }
        .padding()
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
