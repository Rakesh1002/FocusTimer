import SwiftUI

struct SessionNotePromptView: View {
    @EnvironmentObject var sessionJournal: SessionJournal
    @Environment(\.dismiss) private var dismiss
    
    @State private var note = ""
    @State private var selectedMood: SessionNote.Mood?
    @State private var taskCompleted = ""
    @State private var tagInput = ""
    @State private var tags: [String] = []
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("How did it go? ✨")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.textPrimary)
                
                Text("Reflect on your focus session")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            }
            .padding(.top, 24)
            .padding(.bottom, 20)
            
            ScrollView {
                Form {
                    // Mood Selection
                    Section("How did it go?") {
                        HStack(spacing: 12) {
                            ForEach([SessionNote.Mood.great, .good, .okay, .tired, .frustrated], id: \.self) { mood in
                                Button(action: {
                                    selectedMood = mood
                                }) {
                                    VStack(spacing: 4) {
                                        Text(mood.rawValue)
                                            .font(.title2)
                                        Text(mood.description)
                                            .font(.caption2)
                                            .foregroundStyle(Color.textSecondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(selectedMood == mood ? Color.accentPurple.opacity(0.3) : Color.cardBackground.opacity(0.5))
                                    .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // Task Completed
                    Section("What did you work on?") {
                        TextField("e.g., Finished project proposal", text: $taskCompleted)
                    }
                    
                    // Notes
                    Section("Additional notes (optional)") {
                        ZStack(alignment: .topLeading) {
                            Color.inputBackground.opacity(0.5)
                                .cornerRadius(8)
                            
                            TextEditor(text: $note)
                                .frame(minHeight: 100)
                                .scrollContentBackground(.hidden)
                                .padding(8)
                            
                            if note.isEmpty {
                                Text("Add notes here...")
                                    .foregroundStyle(Color.textSecondary.opacity(0.5))
                                    .padding(.horizontal, 13)
                                    .padding(.vertical, 16)
                                    .allowsHitTesting(false)
                            }
                        }
                    }
                    
                    // Tags
                    Section("Tags (optional)") {
                        HStack {
                            TextField("Add tag...", text: $tagInput)
                                .onSubmit {
                                    addTag()
                                }
                            
                            Button("Add") {
                                addTag()
                            }
                            .buttonStyle(.bordered)
                            .disabled(tagInput.isEmpty)
                        }
                        
                        if !tags.isEmpty {
                            FlowLayout(spacing: 8) {
                                ForEach(tags, id: \.self) { tag in
                                    HStack(spacing: 4) {
                                        Text(tag)
                                            .font(.caption)
                                            .foregroundStyle(Color.textPrimary)
                                        Button(action: {
                                            tags.removeAll { $0 == tag }
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.caption2)
                                                .foregroundStyle(Color.textSecondary)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.accentPurple.opacity(0.3))
                                    .cornerRadius(12)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                .formStyle(.grouped)
                .scrollContentBackground(.hidden)
            }
            
            Divider()
            
            // Actions
            HStack(spacing: 12) {
                Button("Skip") {
                    sessionJournal.skipNote()
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Save") {
                    sessionJournal.saveSessionNote(
                        note: note,
                        mood: selectedMood,
                        tags: tags,
                        taskCompleted: taskCompleted.isEmpty ? nil : taskCompleted
                    )
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .background(Color.appBackground)
        .frame(width: 500, height: 600)
        .preferredColorScheme(.dark)
    }
    
    private func addTag() {
        let trimmed = tagInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && !tags.contains(trimmed) {
            tags.append(trimmed)
            tagInput = ""
        }
    }
}

