import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var calendarManager: CalendarManager
    @EnvironmentObject var timerManager: TimerManager
    @State private var showingPermissionAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Calendar")
                .font(.title)
                .padding()
            
            if !calendarManager.hasAccess {
                noAccessView
            } else if calendarManager.upcomingEvents.isEmpty {
                noEventsView
            } else {
                eventsListView
            }
        }
        .frame(width: 400, height: 600)
        .onAppear {
            calendarManager.checkCalendarAccess()
        }
    }
    
    // MARK: - No Access View
    
    private var noAccessView: some View {
        VStack(spacing: 24) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 64))
                .foregroundStyle(.orange)
            
            VStack(spacing: 8) {
                Text("Calendar Access Required")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Focusly needs access to your calendar to suggest focus times around your meetings.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 32)
            }
            
            VStack(spacing: 12) {
                if calendarManager.accessStatus == .notDetermined {
                    // First time asking - system will show permission dialog
                    Button(action: {
                        calendarManager.requestCalendarAccess()
                    }) {
                        Label("Grant Calendar Access", systemImage: "calendar.badge.checkmark")
                            .fontWeight(.semibold)
                            .frame(maxWidth: 280)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .help("This will show a system dialog to grant calendar access")
                } else {
                    // Access was denied - need to open System Settings
                    Button(action: {
                        calendarManager.openSystemPreferences()
                    }) {
                        Label("Open System Settings", systemImage: "gear")
                            .fontWeight(.semibold)
                            .frame(maxWidth: 280)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .help("Opens System Settings to Calendar privacy settings")
                    
                    Button("Recheck Permissions") {
                        calendarManager.checkCalendarAccess()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .help("Check if calendar access was granted")
                }
            }
            
            VStack(spacing: 6) {
                Text("How to enable:")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Text("System Settings → Privacy & Security → Calendars")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 8)
        }
        .padding(32)
    }
    
    // MARK: - No Events View
    
    private var noEventsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.checkmark")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("No Upcoming Events")
                .font(.title2)
            
            Text("Your calendar is clear! Perfect time for deep focus work.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            suggestedFocusTimesView
        }
        .padding()
    }
    
    // MARK: - Events List View
    
    private var eventsListView: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Next Meeting Card
                if let nextMeeting = calendarManager.nextMeeting {
                    nextMeetingCard(nextMeeting)
                }
                
                // Focus Session Check
                focusSessionCheckView
                
                // Upcoming Events List
                LazyVStack(spacing: 8) {
                    ForEach(calendarManager.upcomingEvents.prefix(10)) { event in
                        EventRow(event: event)
                    }
                }
                .padding()
                
                // Suggested Focus Times - now as list!
                suggestedFocusTimesView
                    .padding(.bottom, 80)  // Extra padding to avoid bottom bar
            }
        }
    }
    
    // MARK: - Next Meeting Card
    
    private func nextMeetingCard(_ event: CalendarEvent) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Next Meeting")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let startsIn = event.startsWithin {
                    Text("in \(formatTimeInterval(startsIn))")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.headline)
                        .lineLimit(2)
                    
                    HStack(spacing: 12) {
                        Label(formatTime(event.startDate), systemImage: "clock")
                        Label(formatDuration(event.duration), systemImage: "hourglass")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    // MARK: - Focus Session Check
    
    private var focusSessionCheckView: some View {
        VStack(spacing: 8) {
            if calendarManager.shouldPauseFocus() {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("Meeting starting soon or in progress")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            } else if calendarManager.canFitFocusSession(duration: timerManager.settings.workDuration) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("You have time for a focus session!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            } else {
                HStack {
                    Image(systemName: "clock.badge.exclamationmark")
                        .foregroundColor(.orange)
                    Text("Limited time before next meeting")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Suggested Focus Times
    
    private var suggestedFocusTimesView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Suggested Focus Times")
                .font(.headline)
                .foregroundStyle(Color.textPrimary)
                .padding(.horizontal)
                .padding(.top)
            
            let suggestions = calendarManager.suggestFocusBlocks()
            
            if suggestions.isEmpty {
                Text("No available time slots today")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.bottom)
            } else {
                VStack(spacing: 8) {
                    ForEach(suggestions.prefix(5), id: \.self) { time in
                        FocusTimeSlotRow(
                            startTime: time,
                            duration: timerManager.settings.workDuration,
                            onSelect: {
                                startFocusSession(at: time)
                            }
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
        .background(Color.cardBackground.opacity(0.3))
        .cornerRadius(12)
        .padding(.horizontal, 8)
        .padding(.top, 8)
    }
    
    private func startFocusSession(at time: Date) {
        // For now, just start the timer immediately
        // Future: Could add scheduling/notification for future time slots
        if !timerManager.isRunning {
            timerManager.start()
            // Close popover
            NotificationCenter.default.post(name: NSNotification.Name("ClosePopover"), object: nil)
        }
    }
    
    // MARK: - Helper Functions
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let minutes = Int(interval / 60)
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
    }
}

// MARK: - Event Row

struct EventRow: View {
    let event: CalendarEvent
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 2) {
                Text(formatDay(event.startDate))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(formatDate(event.startDate))
                    .font(.headline)
            }
            .frame(width: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    Label(formatTime(event.startDate), systemImage: "clock")
                    Text("•")
                    Text(formatDuration(event.duration))
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                Text(event.calendar)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(4)
            }
            
            Spacer()
            
            if event.isInProgress {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
            }
        }
        .padding()
        .background(event.isInProgress ? Color.green.opacity(0.1) : Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    private func formatDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
    }
}

// MARK: - Focus Time Slot (Minimal List Style)

struct FocusTimeSlotRow: View {
    let startTime: Date
    let duration: TimeInterval
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: "calendar.badge.clock")
                    .font(.title3)
                    .foregroundColor(Color.accentGreen)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(formatTimeRange())
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text("\(Int(duration / 60)) min available")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                // Arrow indicator
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title3)
                    .foregroundColor(Color.accentGreen.opacity(0.6))
            }
            .padding(12)
            .background(Color.accentGreen.opacity(0.12))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .help("Start focus session at this time")
    }
    
    private func formatTimeRange() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        let start = formatter.string(from: startTime)
        let end = formatter.string(from: startTime.addingTimeInterval(duration))
        
        return "\(start) - \(end)"
    }
}

