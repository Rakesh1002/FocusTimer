import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var soundManager: SoundManager
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Settings")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding()
            
            ScrollView {
                Form {
                    Section("Timer") {
                        HStack {
                            Text("Work Duration:")
                            Spacer()
                            Text("\(Int(settings.workDuration/60)) minutes")
                                .foregroundStyle(.white.opacity(0.9))
                            Stepper("", 
                                   value: Binding(
                                    get: { settings.workDuration/60 },
                                    set: { settings.workDuration = $0 * 60 }
                                   ),
                                   in: 1...120)
                                .labelsHidden()
                        }
                        
                        HStack {
                            Text("Break Duration:")
                            Spacer()
                            Text("\(Int(settings.breakDuration/60)) minutes")
                                .foregroundStyle(.white.opacity(0.9))
                            Stepper("", 
                                   value: Binding(
                                    get: { settings.breakDuration/60 },
                                    set: { settings.breakDuration = $0 * 60 }
                                   ),
                                   in: 1...60)
                                .labelsHidden()
                        }
                        
                        HStack {
                            Text("Work Cycles:")
                            Spacer()
                            Text("\(settings.maxCycles) cycles")
                                .foregroundStyle(.white.opacity(0.9))
                            Stepper("", 
                                   value: $settings.maxCycles,
                                   in: 1...10)
                                .labelsHidden()
                        }
                    }
                    
                    Section("Display") {
                        Toggle("Show Floating Timer", isOn: $settings.showTimeDisplay)
                            .frame(maxWidth: .infinity)
                        
                        if settings.showTimeDisplay {
                            Toggle("Show on All Screens", isOn: $settings.showFloatingTimerOnAllScreens)
                                .frame(maxWidth: .infinity)
                            Text("Display the floating timer on all connected monitors")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        
                        Toggle("Show Break Overlay", isOn: $settings.showBreakOverlay)
                            .frame(maxWidth: .infinity)
                        Toggle("Show Break Activities", isOn: $settings.showBreakActivities)
                            .frame(maxWidth: .infinity)
                    }
                    
                    Section("Sounds") {
                        Toggle("Enable Sounds", isOn: $soundManager.isEnabled)
                            .frame(maxWidth: .infinity)
                        
                        if soundManager.isEnabled {
                            HStack {
                                Text("Volume:")
                                Slider(value: $soundManager.volume, in: 0...1)
                                Text("\(Int(soundManager.volume * 100))%")
                                    .frame(width: 40)
                            }
                            
                            Picker("Work Complete:", selection: $soundManager.workCompleteSound) {
                                ForEach(SoundType.allCases, id: \.self) { sound in
                                    Text(sound.rawValue).tag(sound)
                                }
                            }
                            .onChange(of: soundManager.workCompleteSound) { newValue in
                                soundManager.previewSound(newValue)
                            }
                            
                            Picker("Break Complete:", selection: $soundManager.breakCompleteSound) {
                                ForEach(SoundType.allCases, id: \.self) { sound in
                                    Text(sound.rawValue).tag(sound)
                                }
                            }
                            .onChange(of: soundManager.breakCompleteSound) { newValue in
                                soundManager.previewSound(newValue)
                            }
                            
                            Picker("Session Complete:", selection: $soundManager.sessionCompleteSound) {
                                ForEach(SoundType.allCases, id: \.self) { sound in
                                    Text(sound.rawValue).tag(sound)
                                }
                            }
                            .onChange(of: soundManager.sessionCompleteSound) { newValue in
                                soundManager.previewSound(newValue)
                            }
                        }
                    }
                    
                    Section("Notifications") {
                        Toggle("Break Notifications", isOn: $settings.breakNotifications)
                            .frame(maxWidth: .infinity)
                        Toggle("Session Complete Notifications", isOn: $settings.sessionCompleteNotifications)
                            .frame(maxWidth: .infinity)
                    }
                    
                    Section("Startup") {
                        Toggle("Launch at Login", isOn: $settings.launchAtLogin)
                            .frame(maxWidth: .infinity)
                        Text("Focusly will start automatically when you log in")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    
                    Section("About") {
                        Button(action: {
                            if let url = URL(string: "https://focusly.unquest.ai/privacy") {
                                NSWorkspace.shared.open(url)
                            }
                        }) {
                            HStack {
                                Text("Privacy Policy")
                                    .foregroundStyle(.white.opacity(0.9))
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity)
                        
                        HStack {
                            Text("Version")
                                .foregroundStyle(.white.opacity(0.9))
                            Spacer()
                            Text("1.0.0 (6)")
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                    
                    Section("Keyboard Shortcuts") {
                        VStack(alignment: .leading, spacing: 8) {
                            ShortcutRow(key: "⌘⌥T", action: "Start/Stop Timer")
                            ShortcutRow(key: "⌘⌥R", action: "Reset Timer")
                            ShortcutRow(key: "⌘⌥S", action: "Skip Break")
                            ShortcutRow(key: "⌘⌥B", action: "Toggle Time Display")
                        }
                        .font(.caption)
                    }
                }
                .formStyle(.grouped)
                .scrollContentBackground(.hidden)
            }
        }
        .foregroundStyle(.white)
    }
}

struct ShortcutRow: View {
    let key: String
    let action: String
    
    var body: some View {
        HStack {
            Text(action)
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
            Text(key)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.white.opacity(0.2))
                .cornerRadius(4)
                .foregroundStyle(.white)
        }
    }

}
