import SwiftUI

struct TasksView: View {
    @EnvironmentObject var taskManager: TaskManager
    @EnvironmentObject var timerManager: TimerManager
    @State private var showingAddTask = false
    @State private var showingTaskDetail: Task?
    @State private var selectedFilter: TaskFilter = .active
    
    enum TaskFilter {
        case all, active, completed, today
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Tasks")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)
                
                Spacer()
                
                Button(action: { showingAddTask = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                        Text("New Task")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundStyle(Color.accentBlue)
                }
                .buttonStyle(.plain)
                .help("Add new task")
            }
            .padding()
            .background(Color.cardBackground)
            
            // Filter Tabs
            Picker("Filter", selection: $selectedFilter) {
                Text("Active").tag(TaskFilter.active)
                Text("Today").tag(TaskFilter.today)
                Text("All").tag(TaskFilter.all)
                Text("Done").tag(TaskFilter.completed)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 12)
            
            // Task Suggestion
            if let suggested = taskManager.suggestNextTask(),
               selectedFilter == .active || selectedFilter == .today {
                suggestedTaskCard(suggested)
            }
            
            // Task List
            ScrollView {
                if filteredTasks.isEmpty {
                    emptyStateView
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredTasks) { task in
                            TaskRow(task: task)
                                .onTapGesture {
                                    showingTaskDetail = task
                                }
                        }
                    }
                    .padding()
                }
            }
            
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView()
        }
        .sheet(item: $showingTaskDetail) { task in
            TaskDetailView(task: task)
        }
    }
    
    private var filteredTasks: [Task] {
        switch selectedFilter {
        case .all:
            return taskManager.tasks
        case .active:
            return taskManager.tasks.filter { !$0.isCompleted }
        case .completed:
            return taskManager.tasks.filter { $0.isCompleted }
        case .today:
            return taskManager.getTasksForToday()
        }
    }
    
    private func suggestedTaskCard(_ task: Task) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Suggested Next")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(colorForPriority(task.priority).opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: task.priority.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(colorForPriority(task.priority))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(1)
                    if task.estimatedPomodoros > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "timer")
                                .font(.caption2)
                            Text("\(task.completedPomodoros)/\(task.estimatedPomodoros)")
                                .font(.caption)
                        }
                        .foregroundStyle(Color.textSecondary)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    taskManager.setCurrentTask(task)
                    if !timerManager.isRunning {
                        timerManager.start()
                    }
                    // Close popover when starting a task
                    NotificationCenter.default.post(name: NSNotification.Name("ClosePopover"), object: nil)
                }) {
                    Text("Start")
                        .fontWeight(.semibold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(14)
        .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.orange.opacity(0.3), lineWidth: 1.5)
        )
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: selectedFilter == .completed ? "checkmark.circle" : "tray")
                .font(.system(size: 64))
                .foregroundStyle(.secondary.opacity(0.5))
            
            VStack(spacing: 8) {
                Text(emptyStateTitle)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text(emptyStateMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            if selectedFilter != .completed {
                Button(action: { showingAddTask = true }) {
                    Label("Add Your First Task", systemImage: "plus.circle.fill")
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateTitle: String {
        switch selectedFilter {
        case .all:
            return "No Tasks Yet"
        case .active:
            return "All Caught Up!"
        case .completed:
            return "No Completed Tasks"
        case .today:
            return "Nothing Due Today"
        }
    }
    
    private var emptyStateMessage: String {
        switch selectedFilter {
        case .all:
            return "Start by adding your first task to begin organizing your focus sessions."
        case .active:
            return "You've completed all your tasks. Time to add new goals!"
        case .completed:
            return "Completed tasks will appear here."
        case .today:
            return "No tasks are due today. Enjoy your free time or add a new task!"
        }
    }
    
    private func colorForPriority(_ priority: Task.Priority) -> Color {
        switch priority {
        case .low: return .gray
        case .medium: return .blue
        case .high: return .orange
        case .urgent: return .red
        }
    }
}

// MARK: - Task Row

struct TaskRow: View {
    @EnvironmentObject var taskManager: TaskManager
    let task: Task
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: { taskManager.toggleCompletion(task) }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: task.priority.icon)
                        .font(.caption)
                        .foregroundColor(colorForPriority(task.priority))
                    
                    Text(task.title)
                        .font(.subheadline)
                        .strikethrough(task.isCompleted)
                        .foregroundStyle(task.isCompleted ? Color.textSecondary : Color.textPrimary)
                    
                    if task.isOverdue {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                HStack(spacing: 8) {
                    if task.estimatedPomodoros > 0 {
                        Label("\(task.completedPomodoros)/\(task.estimatedPomodoros)", systemImage: "timer")
                            .font(.caption2)
                            .foregroundStyle(Color.textSecondary)
                    }
                    
                    if let dueDate = task.dueDate {
                        Label(formatDueDate(dueDate), systemImage: "calendar")
                            .font(.caption2)
                            .foregroundStyle(task.isOverdue ? Color.statusError : Color.textSecondary)
                    }
                    
                    if !task.tags.isEmpty {
                        ForEach(task.tags.prefix(2), id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption2)
                                .foregroundStyle(Color.textPrimary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accentBlue.opacity(0.3))
                                .cornerRadius(4)
                        }
                    }
                }
            }
            
            Spacer()
            
            if task.estimatedPomodoros > 0 {
                Button(action: {
                    taskManager.setCurrentTask(task)
                }) {
                    ZStack {
                        CircularProgressView(progress: task.progress)
                            .frame(width: 34, height: 34)
                        
                        if taskManager.currentTask?.id == task.id {
                            Circle()
                                .fill(.orange.opacity(0.2))
                                .frame(width: 10, height: 10)
                        }
                    }
                }
                .buttonStyle(.plain)
                .help("Set as current task")
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background {
            if taskManager.currentTask?.id == task.id {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.cardBackground)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appBackground)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(taskManager.currentTask?.id == task.id ? Color.orange.opacity(0.4) : Color.clear, lineWidth: 1.5)
        )
        .contextMenu {
            if !task.isCompleted {
                Button("Set as Current") {
                    taskManager.setCurrentTask(task)
                }
                
                Button("Add Pomodoro") {
                    taskManager.incrementPomodoro(task)
                }
            }
            
            Button("Delete", role: .destructive) {
                taskManager.deleteTask(task)
            }
        }
    }
    
    private func colorForPriority(_ priority: Task.Priority) -> Color {
        switch priority {
        case .low: return .gray
        case .medium: return .blue
        case .high: return .orange
        case .urgent: return .red
        }
    }
    
    private func formatDueDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Add Task View

struct AddTaskView: View {
    @EnvironmentObject var taskManager: TaskManager
    @Environment(\.dismiss) var dismiss
    
    @State private var title = ""
    @State private var priority: Task.Priority = .medium
    @State private var estimatedPomodoros = 1
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var notes = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Simple Header
            HStack {
                Text("New Task")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.cardBackground)
            
            ScrollView {
                Form {
                    Section("Task Details") {
                        TextField("Task title", text: $title)
                            .frame(maxWidth: .infinity)
                        
                        Picker("Priority", selection: $priority) {
                            ForEach(Task.Priority.allCases, id: \.self) { p in
                                Label(p.displayName, systemImage: p.icon)
                                    .foregroundColor(.white)
                                    .tag(p)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .accentColor(.white)
                    }
                    
                    Section("Estimate") {
                        HStack {
                            Text("Pomodoros:")
                            Spacer()
                            Text("\(estimatedPomodoros)")
                                .foregroundStyle(.white.opacity(0.9))
                            Stepper("", value: $estimatedPomodoros, in: 1...20)
                                .labelsHidden()
                                .tint(.white)
                        }
                    }
                    
                    Section("Due Date") {
                        Toggle("Set due date", isOn: $hasDueDate)
                            .frame(maxWidth: .infinity)
                            .tint(.accentBlue)
                        
                        if hasDueDate {
                            DatePicker("Due", selection: $dueDate, displayedComponents: [.date])
                                .frame(maxWidth: .infinity)
                                .accentColor(.white)
                        }
                    }
                    
                    Section("Notes") {
                        ZStack(alignment: .topLeading) {
                            Color.inputBackground.opacity(0.5)
                                .cornerRadius(8)
                            
                            TextEditor(text: $notes)
                                .frame(minHeight: 80)
                                .scrollContentBackground(.hidden)
                                .padding(8)
                            
                            if notes.isEmpty {
                                Text("Add notes here...")
                                    .foregroundStyle(.white.opacity(0.3))
                                    .padding(.horizontal, 13)
                                    .padding(.vertical, 16)
                                    .allowsHitTesting(false)
                            }
                        }
                    }
                }
                .formStyle(.grouped)
                .scrollContentBackground(.hidden)
                .accentColor(.white)
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                Spacer()
                
                Button("Add Task") {
                    addTask()
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.isEmpty)
            }
            .padding()
            .background(Color.cardBackground)
        }
        .frame(width: 400, height: 480)
        .background(Color.appBackground)
        .foregroundStyle(.white)
        .environment(\.colorScheme, .dark)
    }
    
    private func addTask() {
        let task = Task(
            title: title,
            priority: priority,
            estimatedPomodoros: estimatedPomodoros,
            dueDate: hasDueDate ? dueDate : nil,
            notes: notes.isEmpty ? nil : notes,
            tags: []
        )
        
        taskManager.addTask(task)
        dismiss()
    }
}

// MARK: - Task Detail View

struct TaskDetailView: View {
    @EnvironmentObject var taskManager: TaskManager
    @Environment(\.dismiss) var dismiss
    
    let task: Task
    @State private var editedTask: Task
    
    init(task: Task) {
        self.task = task
        self._editedTask = State(initialValue: task)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Simple Header
            HStack {
                Text("Edit Task")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.cardBackground)
            
            ScrollView {
                Form {
                    Section("Task Details") {
                        TextField("Task title", text: $editedTask.title)
                            .frame(maxWidth: .infinity)
                            .onAppear {
                                // Prevent auto-selection
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    NSApp.keyWindow?.makeFirstResponder(nil)
                                }
                            }
                        
                        Picker("Priority", selection: $editedTask.priority) {
                            ForEach(Task.Priority.allCases, id: \.self) { p in
                                Label(p.displayName, systemImage: p.icon)
                                    .foregroundColor(.white)
                                    .tag(p)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .accentColor(.white)
                    }
                    
                    Section("Progress") {
                        HStack {
                            Text("Completed:")
                            Spacer()
                            Text("\(editedTask.completedPomodoros) / \(editedTask.estimatedPomodoros)")
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        
                        HStack {
                            Text("Estimated:")
                            Spacer()
                            Text("\(editedTask.estimatedPomodoros)")
                                .foregroundStyle(.white.opacity(0.9))
                            Stepper("", value: $editedTask.estimatedPomodoros, in: 1...20)
                                .labelsHidden()
                                .tint(.white)
                        }
                    }
                    
                    Section("Due Date") {
                        Toggle("Set due date", isOn: Binding(
                            get: { editedTask.dueDate != nil },
                            set: { if !$0 { editedTask.dueDate = nil } else { editedTask.dueDate = Date() } }
                        ))
                        .frame(maxWidth: .infinity)
                        .tint(.accentBlue)
                        
                        if editedTask.dueDate != nil {
                            DatePicker("Due", selection: Binding(
                                get: { editedTask.dueDate ?? Date() },
                                set: { editedTask.dueDate = $0 }
                            ), displayedComponents: [.date])
                            .frame(maxWidth: .infinity)
                            .accentColor(.white)
                        }
                    }
                    
                    Section("Notes") {
                        ZStack(alignment: .topLeading) {
                            Color.inputBackground.opacity(0.5)
                                .cornerRadius(8)
                            
                            TextEditor(text: Binding(
                                get: { editedTask.notes ?? "" },
                                set: { editedTask.notes = $0.isEmpty ? nil : $0 }
                            ))
                            .frame(minHeight: 80)
                            .scrollContentBackground(.hidden)
                            .padding(8)
                            
                            if (editedTask.notes ?? "").isEmpty {
                                Text("Add notes here...")
                                    .foregroundStyle(.white.opacity(0.3))
                                    .padding(.horizontal, 13)
                                    .padding(.vertical, 16)
                                    .allowsHitTesting(false)
                            }
                        }
                    }
                }
                .formStyle(.grouped)
                .scrollContentBackground(.hidden)
                .accentColor(.white)
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                Button(role: .destructive) {
                    taskManager.deleteTask(task)
                    dismiss()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Save") {
                    taskManager.updateTask(editedTask)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color.cardBackground)
        }
        .frame(width: 400, height: 500)
        .background(Color.appBackground)
        .foregroundStyle(.white)
        .environment(\.colorScheme, .dark)
    }
}

// MARK: - Supporting Views

struct StatBadge: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 5) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }
            .foregroundStyle(color)
            
            Text(label)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(Color.textSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 10))
    }
}

struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 3)
            
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(progress >= 1.0 ? Color.green : Color.orange, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)
        }
    }
}

