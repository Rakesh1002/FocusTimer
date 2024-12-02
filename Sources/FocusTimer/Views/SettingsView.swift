import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: Settings
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Settings")
                .font(.title)
                .padding(.top)
                .padding(.horizontal)
            
            Form {
                Section("Timer") {
                    HStack {
                        Text("Work Duration:")
                        Spacer()
                        Stepper("\(Int(settings.workDuration/60)) minutes", 
                               value: Binding(
                                get: { settings.workDuration/60 },
                                set: { settings.workDuration = $0 * 60 }
                               ),
                               in: 1...120)
                    }
                    .frame(maxWidth: .infinity)
                    
                    HStack {
                        Text("Break Duration:")
                        Spacer()
                        Stepper("\(Int(settings.breakDuration/60)) minutes", 
                               value: Binding(
                                get: { settings.breakDuration/60 },
                                set: { settings.breakDuration = $0 * 60 }
                               ),
                               in: 1...60)
                    }
                    .frame(maxWidth: .infinity)
                    
                    HStack {
                        Text("Work Cycles:")
                        Spacer()
                        Stepper("\(settings.maxCycles) cycles", 
                               value: $settings.maxCycles,
                               in: 1...10)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                Section("Display") {
                    Toggle("Show Time Display", isOn: $settings.showTimeDisplay)
                        .frame(maxWidth: .infinity)
                    Toggle("Show Break Overlay", isOn: $settings.showBreakOverlay)
                        .frame(maxWidth: .infinity)
                }
                
                Section("Notifications") {
                    Toggle("Break Notifications", isOn: $settings.breakNotifications)
                        .frame(maxWidth: .infinity)
                    Toggle("Session Complete Notifications", isOn: $settings.sessionCompleteNotifications)
                        .frame(maxWidth: .infinity)
                }
            }
            .formStyle(.grouped)
            .frame(maxWidth: .infinity)
        }
        .frame(width: 350)
    }
}
