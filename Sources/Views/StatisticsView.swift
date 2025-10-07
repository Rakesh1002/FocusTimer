import SwiftUI
import Charts

struct StatisticsView: View {
    @EnvironmentObject var statisticsManager: StatisticsManager
    @State private var selectedPeriod: StatsPeriod = .week
    @State private var showExportOptions = false
    @State private var showClearConfirmation = false
    
    enum StatsPeriod: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case all = "All Time"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Text("Statistics")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Summary Cards
                    summaryCards
                    
                    // Period Selector
                    Picker("Period", selection: $selectedPeriod) {
                        ForEach(StatsPeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Chart
                    if #available(macOS 13.0, *) {
                        chartView
                    } else {
                        simpleChartView
                    }
                    
                    // Recent Sessions
                    recentSessionsView
                    
                    // Actions
                    HStack(spacing: 12) {
                        Button("Clear All Stats") {
                            showClearConfirmation = true
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        
                        Button("Export Data") {
                            showExportOptions = true
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                    .padding()
                }
            }
        }
        .foregroundStyle(.white)
        .sheet(isPresented: $showExportOptions) {
            exportOptionsView
        }
        .alert("Clear All Statistics?", isPresented: $showClearConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                statisticsManager.clearAllStats()
            }
        } message: {
            Text("This will permanently delete all your focus sessions, statistics, and history. This action cannot be undone.")
        }
    }
    
    // MARK: - Summary Cards
    
    private var summaryCards: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Total Focus",
                value: formatTime(statisticsManager.totalFocusTime),
                icon: "clock.fill",
                color: .orange
            )
            
            StatCard(
                title: "Sessions",
                value: "\(statisticsManager.totalSessions)",
                icon: "checkmark.circle.fill",
                color: .green
            )
            
            StatCard(
                title: "Streak",
                value: "\(statisticsManager.currentStreak)",
                icon: "flame.fill",
                color: .red
            )
        }
        .padding(.horizontal)
    }
    
    // MARK: - Chart View (macOS 13+)
    
    @available(macOS 13.0, *)
    private var chartView: some View {
        VStack(alignment: .leading) {
            Text("Daily Focus Time")
                .font(.headline)
                .padding(.horizontal)
            
            Chart(chartData) { item in
                BarMark(
                    x: .value("Day", item.date, unit: .day),
                    y: .value("Minutes", item.totalFocusTime / 60)
                )
                .foregroundStyle(.orange.gradient)
            }
            .frame(height: 200)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal)
        }
    }
    
    // MARK: - Simple Chart View (Fallback)
    
    private var simpleChartView: some View {
        VStack(alignment: .leading) {
            Text("Daily Focus Time")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 4) {
                ForEach(chartData) { stat in
                    HStack {
                        Text(formatDate(stat.date))
                            .font(.caption)
                            .frame(width: 60, alignment: .leading)
                        
                        GeometryReader { geometry in
                            let maxValue = chartData.map { $0.totalFocusTime }.max() ?? 1
                            let width = geometry.size.width * CGFloat(stat.totalFocusTime / maxValue)
                            
                            HStack(spacing: 4) {
                                Rectangle()
                                    .fill(Color.orange)
                                    .frame(width: width)
                                
                                Text(stat.formattedFocusTime)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(height: 20)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal)
        }
    }
    
    // MARK: - Recent Sessions
    
    private var recentSessionsView: some View {
        VStack(alignment: .leading) {
            Text("Recent Sessions")
                .font(.headline)
                .padding(.horizontal)
            
            if statisticsManager.sessions.isEmpty {
                Text("No sessions yet. Start your first focus session!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(statisticsManager.sessions.prefix(5)) { session in
                    SessionRow(session: session)
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Export Options
    
    private var exportOptionsView: some View {
        VStack(spacing: 20) {
            Text("Export Statistics")
                .font(.title2)
            
            Button("Export as CSV") {
                exportCSV()
                showExportOptions = false
            }
            .buttonStyle(.bordered)
            
            Button("Export as JSON") {
                exportJSON()
                showExportOptions = false
            }
            .buttonStyle(.bordered)
            
            Button("Cancel") {
                showExportOptions = false
            }
        }
        .padding()
        .frame(width: 300, height: 200)
    }
    
    // MARK: - Data
    
    private var chartData: [DailyStats] {
        switch selectedPeriod {
        case .week:
            return statisticsManager.getWeeklyStats()
        case .month:
            return statisticsManager.getMonthlyStats()
        case .all:
            return statisticsManager.getMonthlyStats() // Limit to 30 days for performance
        }
    }
    
    // MARK: - Helpers
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    private func exportCSV() {
        let csv = statisticsManager.exportToCSV()
        saveToFile(content: csv, filename: "focusly-stats.csv")
    }
    
    private func exportJSON() {
        if let data = statisticsManager.exportToJSON(),
           let json = String(data: data, encoding: .utf8) {
            saveToFile(content: json, filename: "focusly-stats.json")
        }
    }
    
    private func saveToFile(content: String, filename: String) {
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = filename
        savePanel.canCreateDirectories = true
        
        if savePanel.runModal() == .OK, let url = savePanel.url {
            try? content.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct SessionRow: View {
    let session: FocusSession
    
    var body: some View {
        HStack {
            Image(systemName: session.wasCompleted ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(session.wasCompleted ? .green : .red)
            
            VStack(alignment: .leading, spacing: 2) {
                if let task = session.taskLabel {
                    Text(task)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Text(formatSessionDate(session.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(session.duration / 60))m")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(session.cyclesCompleted) cycles")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatSessionDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

