import SwiftUI

enum MenuBarTab {
    case main
    case tasks
    case calendar
    case statistics
    case settings
    case presets
    case journal
}

struct MenuBarView: View {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var timerManager: TimerManager
    @EnvironmentObject var statisticsManager: StatisticsManager
    @EnvironmentObject var taskManager: TaskManager
    @EnvironmentObject var calendarManager: CalendarManager
    @EnvironmentObject var presetManager: PresetManager
    @EnvironmentObject var sessionJournal: SessionJournal
    @EnvironmentObject var breakActivityManager: BreakActivityManager
    @State private var currentTab: MenuBarTab = .main
    @State private var showingBreakActivity = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Content with vibrant background
            Group {
                switch currentTab {
                case .main:
                    mainView
                case .tasks:
                    TasksView()
                        .frame(height: 500)
                case .calendar:
                    CalendarView()
                        .frame(height: 500)
                case .statistics:
                    StatisticsView()
                        .frame(height: 500)
                case .settings:
                    SettingsView(isPresented: Binding(
                        get: { currentTab == .settings },
                        set: { if !$0 { currentTab = .main } }
                    ))
                    .frame(height: 500)
                case .presets:
                    PresetPickerView()
                        .frame(height: 500)
                case .journal:
                    SessionJournalView()
                        .frame(height: 500)
                }
            }
            .frame(maxWidth: .infinity)
            .background(Color.appBackground)
            
            // Bottom navigation with glass effect
            HStack(spacing: 8) {
                if currentTab != .main {
                    Button(action: { currentTab = .main }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .help("Back")
                } else {
                    Button(action: { currentTab = .tasks }) {
                        Image(systemName: "checklist")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.accentBlue)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .help("Tasks")
                    
                    Button(action: { currentTab = .calendar }) {
                        Image(systemName: "calendar")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.accentOrange)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .help("Calendar")
                    
                    Button(action: { currentTab = .statistics }) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.accentGreen)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .help("Statistics")
                }
                
                Spacer()
                
                // Show Quit on Settings screen, Settings button otherwise
                if currentTab == .settings {
                    Button(action: { NSApplication.shared.terminate(nil) }) {
                        Image(systemName: "power")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.red.opacity(0.9))
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .help("Quit Focusly")
                } else {
                    Button(action: { currentTab = .settings }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white.opacity(0.9))
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .help("Settings")
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(Color.cardBackground)
        }
    }
    
    private var mainView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Button(action: { currentTab = .presets }) {
                    HStack(spacing: 6) {
                        Image(systemName: presetManager.currentPreset.icon)
                            .foregroundStyle(colorFromString(presetManager.currentPreset.color))
                            .font(.system(size: 13, weight: .medium))
                        Text(presetManager.currentPreset.name)
                            .font(.system(size: 12, weight: .medium))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(colorFromString(presetManager.currentPreset.color).opacity(0.5), lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
                .help("Change timer preset")
                
                Spacer()
                
                Button(action: { currentTab = .journal }) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.accentPurple)
                        .frame(width: 34, height: 34)
                        .background(Color.cardBackground, in: Circle())
                }
                .buttonStyle(.plain)
                .help("Session journal")
            }
            .padding(.horizontal, 10)
            .padding(.top, 10)
            
            Text(timerManager.isBreakTime ? "Break Time!" : "Focus Time")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(Color.textPrimary)
            
            // Current Task Display
            if let currentTask = taskManager.currentTask {
                VStack(spacing: 8) {
                    Text("Working on:")
                        .font(.caption)
                        .foregroundStyle(Color.textTertiary)
                    Text(currentTask.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                            .font(.caption2)
                        Text("\(currentTask.completedPomodoros)/\(currentTask.estimatedPomodoros)")
                            .font(.caption)
                    }
                    .foregroundStyle(Color.textSecondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.accentBlue.opacity(0.4), lineWidth: 1.5)
                        )
                )
                .padding(.horizontal)
            }
            
            Text(formatTime(timerManager.remainingTime))
                .font(.system(size: 56, weight: .bold, design: .monospaced))
                .foregroundStyle(timerManager.isBreakTime ? Color.accentOrange : Color.accentBlue)
                .padding(.vertical, 12)
                .shadow(color: (timerManager.isBreakTime ? Color.accentOrange : Color.accentBlue).opacity(0.3), radius: 20, y: 0)
                .scaleEffect(timerManager.isRunning ? 1.0 : 0.98)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: timerManager.isRunning)
            
            // Primary Action - Following Apple HIG for critical actions
            VStack(spacing: 12) {
                Button(action: {
                    if timerManager.isRunning {
                        timerManager.stop()
                    } else {
                        timerManager.start()
                        // Close popover when starting timer
                        NotificationCenter.default.post(name: NSNotification.Name("ClosePopover"), object: nil)
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: timerManager.isRunning ? "stop.fill" : "play.fill")
                            .font(.system(size: 20, weight: .bold))
                        Text(timerManager.isRunning ? "Stop" : "Start")
                            .font(.system(size: 19, weight: .bold))
                    }
                    .frame(width: 200, height: 56)
                    .foregroundStyle(.white)
                }
                .buttonStyle(PrimaryButtonStyle(color: timerManager.isRunning ? .statusError : .statusSuccess))
                .shadow(color: (timerManager.isRunning ? Color.statusError : Color.statusSuccess).opacity(0.4), radius: 12, y: 6)
                
                if timerManager.isBreakTime {
                    Button("Skip Break") {
                        timerManager.skipBreakStartWork()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .transition(.smoothScale)
                }
            }
            
            // More user-friendly cycle display
            if timerManager.isRunning {
                Text("Work block \(timerManager.currentCycle + 1) of \(settings.maxCycles)")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            } else {
                Text("Ready for \(settings.maxCycles) work blocks")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            }
            
            // Minimal Task Stats
            if !taskManager.tasks.isEmpty {
                HStack(spacing: 8) {
                    Button(action: { currentTab = .tasks }) {
                        minimalStat(icon: "circle", value: taskManager.activeTaskCount, color: .blue, label: "active")
                    }
                    .buttonStyle(.plain)
                    .help("Active tasks")
                    
                    if taskManager.overdueTaskCount > 0 {
                        Button(action: { currentTab = .tasks }) {
                            minimalStat(icon: "exclamationmark.triangle.fill", value: taskManager.overdueTaskCount, color: .red, label: "overdue")
                        }
                        .buttonStyle(.plain)
                        .help("Overdue tasks")
                    }
                    
                    if taskManager.todayTaskCount > 0 {
                        Button(action: { currentTab = .tasks }) {
                            minimalStat(icon: "sun.max.fill", value: taskManager.todayTaskCount, color: Color.accentYellow, label: "today")
                        }
                        .buttonStyle(.plain)
                        .help("Today's tasks")
                    }
                }
                .padding(.top, 4)
            }
            
            // Calendar Warning
            if calendarManager.shouldPauseFocus() && timerManager.isRunning {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.statusWarning)
                    Text("Meeting starting soon")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.textPrimary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.statusWarning.opacity(0.2), in: RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.statusWarning, lineWidth: 1.5)
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .sheet(isPresented: $showingBreakActivity) {
            BreakActivityPromptView(breakDuration: settings.breakDuration)
        }
        .onChange(of: timerManager.isBreakTime) { isBreak in
            if isBreak && settings.showBreakActivities {
                showingBreakActivity = true
            }
        }
        .onChange(of: settings.showFloatingTimerOnAllScreens) { _ in
            // Refresh floating timer windows when multi-screen setting changes
            if settings.showTimeDisplay {
                WindowManager.shared.hideTimeDisplay()
                WindowManager.shared.showTimeDisplay()
            }
        }
        .onChange(of: settings.showBreakOverlay) { show in
            if !show {
                WindowManager.shared.hideBreakOverlay()
            }
        }
        .sheet(isPresented: $sessionJournal.showJournalPrompt) {
            SessionNotePromptView()
        }
    }
    
    private func colorFromString(_ colorName: String) -> Color {
        switch colorName.lowercased() {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "pink": return .pink
        default: return .blue
        }
    }
    
    private func quickStat(value: String, label: String, color: Color, emphasized: Bool = false) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: emphasized ? 30 : 24, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .shadow(color: color.opacity(0.3), radius: emphasized ? 8 : 4, y: 2)
            Text(label)
                .font(emphasized ? .caption : .caption2)
                .fontWeight(emphasized ? .bold : .semibold)
                .foregroundStyle(Color.textPrimary)
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .padding(.horizontal, emphasized ? 20 : 16)
        .padding(.vertical, emphasized ? 16 : 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(emphasized ? color.opacity(0.2) : Color.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(color, lineWidth: emphasized ? 2.5 : 1.5)
                )
        )
        .shadow(color: emphasized ? color.opacity(0.5) : Color.black.opacity(0.2), radius: emphasized ? 12 : 8, y: emphasized ? 6 : 4)
    }
    
    private func vibrancyColor(for baseColor: Color) -> Color {
        switch baseColor {
        case .blue:
            return Color(red: 0.4, green: 0.7, blue: 1.0)
        case .orange:
            return Color(red: 1.0, green: 0.7, blue: 0.3)
        case .red:
            return Color(red: 1.0, green: 0.4, blue: 0.4)
        case .green:
            return Color(red: 0.5, green: 0.9, blue: 0.5)
        default:
            return baseColor
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func compactStat(icon: String, value: Int, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(color)
            Text("\(value)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 6))
    }
    
    private func minimalStat(icon: String, value: Int, color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(color)
            Text("\(value)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.2), in: RoundedRectangle(cornerRadius: 6))
    }
}
