import SwiftUI

struct SessionJournalView: View {
    @EnvironmentObject var sessionJournal: SessionJournal
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedNote: SessionNote?
    @State private var showingExportSheet = false
    @State private var filterTag: String?
    
    var filteredNotes: [SessionNote] {
        if let tag = filterTag {
            return sessionJournal.notesWithTag(tag)
        }
        return sessionJournal.notes
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Session Journal")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Menu {
                    Button(action: { exportToMarkdown() }) {
                        Label("Export to Markdown", systemImage: "arrow.down.doc")
                    }
                    if filterTag != nil {
                        Button(action: { filterTag = nil }) {
                            Label("Clear Filter", systemImage: "xmark.circle")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.accentBlue)
                }
                .menuStyle(.borderlessButton)
            }
            .padding()
            .background(Color.cardBackground)
            
            // Filter Tags
            if !sessionJournal.allTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(sessionJournal.allTags, id: \.self) { tag in
                            tagButton(tag)
                        }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 12)
            .background(Color.cardBackground)
            }
            
            // Notes List
            ScrollView {
                if filteredNotes.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 52))
                            .foregroundStyle(.tertiary)
                        Text("No journal entries yet")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Complete a focus session to start journaling")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 80)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredNotes) { note in
                            SessionNoteCard(note: note)
                                .onTapGesture {
                                    selectedNote = note
                                }
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(item: $selectedNote) { note in
            SessionNoteDetailView(note: note)
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportView(markdown: sessionJournal.exportToMarkdown())
        }
    }
    
    private func exportToMarkdown() {
        showingExportSheet = true
    }
    
    @ViewBuilder
    private func tagButton(_ tag: String) -> some View {
        Button(action: {
            filterTag = filterTag == tag ? nil : tag
        }) {
            Text(tag)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
        }
        .buttonStyle(.plain)
        .background(filterTag == tag ? Color.accentColor : Color.gray.opacity(0.15), in: Capsule())
        .foregroundStyle(filterTag == tag ? .white : .primary)
    }
}

struct SessionNoteCard: View {
    let note: SessionNote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(alignment: .top, spacing: 12) {
                if let mood = note.mood {
                    Text(mood.rawValue)
                        .font(.system(size: 32))
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(note.date, style: .date)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                    Text(note.date, style: .time)
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 3) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.caption2)
                        Text("\(Int(note.sessionDuration / 60))m")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(Color.textPrimary)
                    Text("\(note.cyclesCompleted) cycles")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            
            // Task
            if let task = note.taskCompleted {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.system(size: 14))
                    Text(task)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            }
            
            // Note
            if !note.note.isEmpty {
                Text(note.note)
                    .font(.body)
                    .lineLimit(3)
                    .foregroundStyle(Color.textSecondary)
            }
            
            // Tags
            if !note.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(note.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundStyle(Color.textPrimary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.accentPurple.opacity(0.3), in: Capsule())
                        }
                    }
                }
            }
        }
        .padding(14)
        .card(cornerRadius: 14)
    }
}

struct SessionNoteDetailView: View {
    @EnvironmentObject var sessionJournal: SessionJournal
    @Environment(\.dismiss) private var dismiss
    
    let note: SessionNote
    
    @State private var isEditing = false
    @State private var editedNote: String
    @State private var editedMood: SessionNote.Mood?
    @State private var editedTags: [String]
    @State private var editedTask: String
    
    init(note: SessionNote) {
        self.note = note
        _editedNote = State(initialValue: note.note)
        _editedMood = State(initialValue: note.mood)
        _editedTags = State(initialValue: note.tags)
        _editedTask = State(initialValue: note.taskCompleted ?? "")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Session Details")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                if isEditing {
                    Button("Save") {
                        saveChanges()
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Edit") {
                        isEditing = true
                    }
                }
                Button("Close") {
                    dismiss()
                }
                .padding(.leading, 8)
            }
            .padding()
            .background(Color.cardBackground)
            
            ScrollView {
                Form {
                    // Date & Duration
                    Section {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Date")
                                    .font(.caption)
                                    .foregroundStyle(Color.textSecondary)
                                Text(note.date, style: .date)
                                    .font(.headline)
                                    .foregroundStyle(Color.textPrimary)
                                Text(note.date, style: .time)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.textSecondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("Duration")
                                    .font(.caption)
                                    .foregroundStyle(Color.textSecondary)
                                Text("\(Int(note.sessionDuration / 60)) minutes")
                                    .font(.headline)
                                    .foregroundStyle(Color.textPrimary)
                                Text("\(note.cyclesCompleted) cycles")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.textSecondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // Mood
                    Section("How did it go?") {
                        if isEditing {
                            HStack(spacing: 12) {
                                ForEach([SessionNote.Mood.great, .good, .okay, .tired, .frustrated], id: \.self) { mood in
                                    Button(action: {
                                        editedMood = mood
                                    }) {
                                        VStack(spacing: 4) {
                                            Text(mood.rawValue)
                                                .font(.title2)
                                            Text(mood.description)
                                                .font(.caption2)
                                                .foregroundStyle(Color.textSecondary)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(editedMood == mood ? Color.accentPurple.opacity(0.3) : Color.cardBackground.opacity(0.5))
                                        .cornerRadius(8)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 8)
                        } else if let mood = note.mood {
                            HStack {
                                Text(mood.rawValue)
                                    .font(.title)
                                Text(mood.description)
                                    .font(.headline)
                                    .foregroundStyle(Color.textPrimary)
                            }
                            .padding(.vertical, 8)
                        } else {
                            Text("Not specified")
                                .foregroundStyle(Color.textSecondary)
                                .padding(.vertical, 8)
                        }
                    }
                    
                    // Task Completed
                    Section("Task Completed") {
                        if isEditing {
                            TextField("What did you work on?", text: $editedTask)
                        } else if !editedTask.isEmpty {
                            Text(editedTask)
                                .foregroundStyle(Color.textPrimary)
                        } else {
                            Text("Not specified")
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                    
                    // Notes
                    Section("Notes") {
                        if isEditing {
                            ZStack(alignment: .topLeading) {
                                Color.inputBackground.opacity(0.5)
                                    .cornerRadius(8)
                                
                                TextEditor(text: $editedNote)
                                    .frame(minHeight: 100)
                                    .scrollContentBackground(.hidden)
                                    .padding(8)
                                
                                if editedNote.isEmpty {
                                    Text("Add notes here...")
                                        .foregroundStyle(Color.textSecondary.opacity(0.5))
                                        .padding(.horizontal, 13)
                                        .padding(.vertical, 16)
                                        .allowsHitTesting(false)
                                }
                            }
                        } else if !note.note.isEmpty {
                            Text(note.note)
                                .foregroundStyle(Color.textPrimary)
                        } else {
                            Text("No notes")
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                    
                    // Tags
                    Section("Tags") {
                        if !note.tags.isEmpty {
                            FlowLayout(spacing: 8) {
                                ForEach(note.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .foregroundStyle(Color.textPrimary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.accentPurple.opacity(0.3))
                                        .cornerRadius(12)
                                }
                            }
                            .padding(.vertical, 8)
                        } else {
                            Text("No tags")
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                }
                .formStyle(.grouped)
                .scrollContentBackground(.hidden)
            }
        }
        .background(Color.appBackground)
        .frame(width: 500, height: 600)
        .preferredColorScheme(.dark)
    }
    
    private func saveChanges() {
        var updatedNote = note
        updatedNote.note = editedNote
        updatedNote.mood = editedMood
        updatedNote.tags = editedTags
        updatedNote.taskCompleted = editedTask.isEmpty ? nil : editedTask
        
        sessionJournal.updateNote(updatedNote)
        isEditing = false
    }
}

// Simple flow layout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize
        var positions: [CGPoint]
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var positions: [CGPoint] = []
            var size: CGSize = .zero
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let subviewSize = subview.sizeThatFits(.unspecified)
                
                if currentX + subviewSize.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: currentX, y: currentY))
                currentX += subviewSize.width + spacing
                lineHeight = max(lineHeight, subviewSize.height)
                size.width = max(size.width, currentX)
            }
            
            size.height = currentY + lineHeight
            self.size = size
            self.positions = positions
        }
    }
}

struct ExportView: View {
    @Environment(\.dismiss) private var dismiss
    let markdown: String
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Export Journal")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Button("Done") {
                    dismiss()
                }
            }
            .padding()
            .background(Color.cardBackground)
            
            ScrollView {
                Text(markdown)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(Color.textPrimary)
                    .textSelection(.enabled)
                    .padding()
            }
            
            Divider()
            
            HStack {
                Spacer()
                Button("Copy to Clipboard") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(markdown, forType: .string)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color.cardBackground)
        }
        .background(Color.appBackground)
        .frame(width: 500, height: 600)
        .preferredColorScheme(.dark)
    }
}

