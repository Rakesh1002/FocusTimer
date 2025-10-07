import SwiftUI

struct BreakActivityPromptView: View {
    @EnvironmentObject var breakActivityManager: BreakActivityManager
    @Environment(\.dismiss) private var dismiss
    
    let breakDuration: TimeInterval
    
    @State private var suggestedActivity: BreakActivity
    @State private var showingAllActivities = false
    
    init(breakDuration: TimeInterval) {
        self.breakDuration = breakDuration
        // We'll set the actual suggested activity in onAppear
        _suggestedActivity = State(initialValue: BreakActivity.builtInActivities[0])
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("Break Time! 🎉")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                
                Text("Your break is \(Int(breakDuration / 60)) minutes")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            }
            
            // Suggested Activity
            VStack(spacing: 16) {
                Text("Suggested Activity")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textSecondary)
                    .textCase(.uppercase)
                
                ActivityCard(activity: suggestedActivity, isDetailed: true)
                
                HStack(spacing: 10) {
                    Button(action: {
                        breakActivityManager.markActivityCompleted(suggestedActivity)
                        dismiss()
                    }) {
                        Text("Done")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    Button(action: { dismiss() }) {
                        Text("Skip")
                            .fontWeight(.medium)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    
                    Button(action: {
                        suggestedActivity = breakActivityManager.suggestActivity(for: breakDuration)
                    }) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .help("Different suggestion")
                }
            }
            .padding(18)
            .card(cornerRadius: 16)
            
            // Browse Activities
            Button(action: { showingAllActivities = true }) {
                Label("Browse All Activities", systemImage: "list.bullet")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.accentBlue)
        }
        .padding(28)
        .frame(width: 420)
        .onAppear {
            suggestedActivity = breakActivityManager.suggestActivity(for: breakDuration)
        }
        .sheet(isPresented: $showingAllActivities) {
            AllActivitiesView(breakDuration: breakDuration) { activity in
                breakActivityManager.markActivityCompleted(activity)
                dismiss()
            }
        }
    }
}

struct ActivityCard: View {
    let activity: BreakActivity
    let isDetailed: Bool
    let onSelect: (() -> Void)?
    
    init(activity: BreakActivity, isDetailed: Bool = false, onSelect: (() -> Void)? = nil) {
        self.activity = activity
        self.isDetailed = isDetailed
        self.onSelect = onSelect
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    Circle()
                        .fill(categoryColor.opacity(0.15))
                        .frame(width: isDetailed ? 64 : 44, height: isDetailed ? 64 : 44)
                    Image(systemName: activity.icon)
                        .font(.system(size: isDetailed ? 28 : 20, weight: .medium))
                        .foregroundStyle(categoryColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.title)
                        .font(isDetailed ? .title3 : .headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.textPrimary)
                    
                    HStack(spacing: 6) {
                        Image(systemName: activity.category.icon)
                            .font(.caption2)
                        Text(activity.category.rawValue)
                            .font(.caption)
                        
                        Text("•")
                            .font(.caption)
                        
                        HStack(spacing: 3) {
                            Image(systemName: "clock.fill")
                                .font(.caption2)
                            Text("\(activity.duration) min")
                                .font(.caption)
                        }
                    }
                    .foregroundStyle(Color.textSecondary)
                }
                
                Spacer()
                
                if let onSelect = onSelect {
                    Button(action: onSelect) {
                        Text("Select")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            
            if isDetailed {
                Text(activity.description)
                    .font(.callout)
                    .foregroundStyle(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(isDetailed ? 18 : 14)
        .card(cornerRadius: 14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(categoryColor, lineWidth: 1.5)
        )
    }
    
    private var categoryColor: Color {
        switch activity.category.color {
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
}

struct AllActivitiesView: View {
    @EnvironmentObject var breakActivityManager: BreakActivityManager
    @Environment(\.dismiss) private var dismiss
    
    let breakDuration: TimeInterval
    let onSelect: (BreakActivity) -> Void
    
    @State private var selectedCategory: BreakActivity.Category?
    @State private var showingAddActivity = false
    
    var filteredActivities: [BreakActivity] {
        let activities = selectedCategory == nil 
            ? breakActivityManager.activities 
            : breakActivityManager.activitiesByCategory(selectedCategory!)
        
        // Filter by break duration
        return activities.filter { $0.duration <= Int(breakDuration / 60) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with glass effect
            HStack {
                Text("Break Activities")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Button(action: { showingAddActivity = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.accentGreen)
                }
                .buttonStyle(.plain)
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.statusError)
                }
                .buttonStyle(.plain)
                .padding(.leading, 8)
            }
            .padding()
            .background(Color.cardBackground)
            
            // Category Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    CategoryFilterButton(
                        title: "All",
                        icon: "square.grid.2x2",
                        isSelected: selectedCategory == nil,
                        action: { selectedCategory = nil }
                    )
                    
                    ForEach(BreakActivity.Category.allCases, id: \.self) { category in
                        CategoryFilterButton(
                            title: category.rawValue,
                            icon: category.icon,
                            isSelected: selectedCategory == category,
                            action: { selectedCategory = category }
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 14)
            .background(Color.cardBackground)
            
            // Activities List
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredActivities) { activity in
                        ActivityCard(activity: activity, onSelect: {
                            onSelect(activity)
                        })
                    }
                }
                .padding()
            }
        }
        .sheet(isPresented: $showingAddActivity) {
            AddActivityView()
        }
    }
}

struct CategoryFilterButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
        }
        .buttonStyle(.plain)
        .background(isSelected ? Color.accentColor : Color.gray.opacity(0.15), in: Capsule())
        .foregroundStyle(isSelected ? .white : .primary)
    }
}

struct AddActivityView: View {
    @EnvironmentObject var breakActivityManager: BreakActivityManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var duration = 5
    @State private var category: BreakActivity.Category = .physical
    @State private var selectedIcon = "figure.walk"
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Add Custom Activity")
                    .font(.title2)
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
            }
            .padding()
            
            Divider()
            
            Form {
                Section("Details") {
                    TextField("Activity Title", text: $title)
                    TextField("Description", text: $description)
                    Stepper("Duration: \(duration) min", value: $duration, in: 1...30)
                }
                
                Section("Category & Icon") {
                    Picker("Category", selection: $category) {
                        ForEach(BreakActivity.Category.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                        }
                    }
                    
                    Picker("Icon", selection: $selectedIcon) {
                        ForEach(["figure.walk", "figure.flexibility", "eye.fill", "drop.fill", "message.fill", "music.note", "leaf.fill"], id: \.self) { icon in
                            Label(icon, systemImage: icon).tag(icon)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            
            Divider()
            
            HStack {
                Spacer()
                Button("Add Activity") {
                    let activity = BreakActivity(
                        title: title,
                        description: description,
                        duration: duration,
                        category: category,
                        icon: selectedIcon,
                        isCustom: true
                    )
                    breakActivityManager.addActivity(activity)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.isEmpty || description.isEmpty)
            }
            .padding()
        }
        .frame(width: 400, height: 500)
    }
}

