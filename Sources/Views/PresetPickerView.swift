import SwiftUI

struct PresetPickerView: View {
    @EnvironmentObject var presetManager: PresetManager
    @EnvironmentObject var timerManager: TimerManager
    @EnvironmentObject var settings: Settings
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingAddPreset = false
    @State private var editingPreset: TimerPreset?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Timer Presets")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Button(action: { showingAddPreset = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                        Text("Add Preset")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(Color.accentBlue)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.cardBackground)
            
            ScrollView {
                VStack(spacing: 20) {
                    // Built-in Presets
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Built-in Presets")
                            .font(.headline)
                            .foregroundStyle(Color.textSecondary)
                        
                        ForEach(presetManager.builtInPresets) { preset in
                            PresetCard(
                                preset: preset,
                                isSelected: preset.id == presetManager.currentPreset.id,
                                onSelect: {
                                    selectPreset(preset)
                                },
                                onEdit: nil,
                                onDelete: nil
                            )
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // Custom Presets
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Custom Presets")
                            .font(.headline)
                            .foregroundStyle(Color.textSecondary)
                        
                        if presetManager.customPresets.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "timer.circle")
                                    .font(.system(size: 36))
                                    .foregroundStyle(Color.textTertiary)
                                Text("No custom presets yet")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.textSecondary)
                                Text("Create one to get started!")
                                    .font(.caption)
                                    .foregroundStyle(Color.textTertiary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                            .card(cornerRadius: 12)
                        } else {
                            ForEach(presetManager.customPresets) { preset in
                                PresetCard(
                                    preset: preset,
                                    isSelected: preset.id == presetManager.currentPreset.id,
                                    onSelect: {
                                        selectPreset(preset)
                                    },
                                    onEdit: {
                                        editingPreset = preset
                                    },
                                    onDelete: {
                                        presetManager.deletePreset(preset)
                                    }
                                )
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .sheet(isPresented: $showingAddPreset) {
            PresetEditorView(preset: nil)
        }
        .sheet(item: $editingPreset) { preset in
            PresetEditorView(preset: preset)
        }
    }
    
    private func selectPreset(_ preset: TimerPreset) {
        // Stop timer if running
        if timerManager.isRunning {
            timerManager.stop()
        }
        
        // Update preset
        presetManager.setCurrentPreset(preset)
        
        // Apply to settings and timer
        settings.workDuration = preset.workDuration
        settings.breakDuration = preset.breakDuration
        settings.maxCycles = preset.maxCycles
        
        timerManager.remainingTime = preset.workDuration
        timerManager.currentCycle = 0
    }
}

struct PresetCard: View {
    let preset: TimerPreset
    let isSelected: Bool
    let onSelect: () -> Void
    let onEdit: (() -> Void)?
    let onDelete: (() -> Void)?
    
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        Button(action: {
            if !isSelected {
                onSelect()
            }
        }) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    Circle()
                        .fill(colorFromString(preset.color).opacity(0.2))
                        .frame(width: 48, height: 48)
                    Image(systemName: preset.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(colorFromString(preset.color))
                }
                .shadow(color: colorFromString(preset.color).opacity(0.3), radius: 4, y: 2)
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(preset.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                    Text(preset.description)
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer(minLength: 8)
                
                // Status & Actions
                HStack(spacing: 10) {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.statusSuccess)
                            .font(.title3)
                    }
                    
                    if let onEdit = onEdit {
                        Button(action: onEdit) {
                            Image(systemName: "pencil.circle.fill")
                                .font(.title3)
                                .foregroundStyle(Color.accentBlue)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if let onDelete = onDelete {
                        Button(action: { showingDeleteConfirmation = true }) {
                            Image(systemName: "trash.circle.fill")
                                .font(.title3)
                                .foregroundStyle(Color.statusError)
                        }
                        .buttonStyle(.plain)
                        .confirmationDialog(
                            "Delete \(preset.name)?",
                            isPresented: $showingDeleteConfirmation,
                            titleVisibility: .visible
                        ) {
                            Button("Delete", role: .destructive) {
                                onDelete()
                            }
                            Button("Cancel", role: .cancel) {}
                        }
                    }
                }
            }
            .padding(16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isSelected ? Color.cardBackgroundHover : Color.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isSelected ? colorFromString(preset.color) : Color.white.opacity(0.1), lineWidth: isSelected ? 2.5 : 1)
        )
        .shadow(color: isSelected ? colorFromString(preset.color).opacity(0.4) : Color.black.opacity(0.2), radius: isSelected ? 12 : 6, y: isSelected ? 6 : 3)
    }
    
    private func colorFromString(_ colorName: String) -> Color {
        switch colorName.lowercased() {
        case "red": return Color.statusError
        case "orange": return Color.accentOrange
        case "yellow": return Color.accentYellow
        case "green": return Color.accentGreen
        case "blue": return Color.accentBlue
        case "purple": return Color.accentPurple
        case "pink": return Color.accentOrange
        default: return Color.accentBlue
        }
    }
}

struct PresetEditorView: View {
    @EnvironmentObject var presetManager: PresetManager
    @Environment(\.dismiss) private var dismiss
    
    let preset: TimerPreset?
    
    @State private var name: String
    @State private var workMinutes: Int
    @State private var breakMinutes: Int
    @State private var cycles: Int
    @State private var selectedIcon: String
    @State private var selectedColor: String
    
    private let availableIcons = [
        "timer", "clock.fill", "hourglass", "stopwatch.fill",
        "flame.fill", "bolt.fill", "star.fill", "brain.head.profile",
        "book.fill", "pencil", "paintbrush.fill", "hare.fill"
    ]
    
    private let availableColors = [
        "red", "orange", "yellow", "green", "blue", "purple", "pink"
    ]
    
    init(preset: TimerPreset?) {
        self.preset = preset
        _name = State(initialValue: preset?.name ?? "")
        _workMinutes = State(initialValue: preset?.workMinutes ?? 25)
        _breakMinutes = State(initialValue: preset?.breakMinutes ?? 5)
        _cycles = State(initialValue: preset?.maxCycles ?? 4)
        _selectedIcon = State(initialValue: preset?.icon ?? "timer")
        _selectedColor = State(initialValue: preset?.color ?? "blue")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(preset == nil ? "New Preset" : "Edit Preset")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white.opacity(0.7))
            }
            .padding()
            .background(Color.cardBackground)
            
            ScrollView {
                Form {
                    Section("Details") {
                        TextField("Preset Name", text: $name)
                            .frame(maxWidth: .infinity)
                        
                        HStack {
                            Text("Work:")
                            Spacer()
                            Text("\(workMinutes) min")
                                .foregroundStyle(.white.opacity(0.9))
                            Stepper("", value: $workMinutes, in: 1...120)
                                .labelsHidden()
                                .tint(.white)
                        }
                        
                        HStack {
                            Text("Break:")
                            Spacer()
                            Text("\(breakMinutes) min")
                                .foregroundStyle(.white.opacity(0.9))
                            Stepper("", value: $breakMinutes, in: 1...30)
                                .labelsHidden()
                                .tint(.white)
                        }
                        
                        HStack {
                            Text("Cycles:")
                            Spacer()
                            Text("\(cycles)")
                                .foregroundStyle(.white.opacity(0.9))
                            Stepper("", value: $cycles, in: 1...10)
                                .labelsHidden()
                                .tint(.white)
                        }
                    }
                    
                    Section("Appearance") {
                        Picker("Icon", selection: $selectedIcon) {
                            ForEach(availableIcons, id: \.self) { icon in
                                Label(icon, systemImage: icon)
                                    .foregroundColor(.white)
                                    .tag(icon)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .accentColor(.white)
                        
                        Picker("Color", selection: $selectedColor) {
                            ForEach(availableColors, id: \.self) { color in
                                HStack {
                                    Circle()
                                        .fill(colorFromString(color))
                                        .frame(width: 16, height: 16)
                                    Text(color.capitalized)
                                        .foregroundColor(.white)
                                }.tag(color)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .accentColor(.white)
                    }
                    
                    Section("Preview") {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(colorFromString(selectedColor).opacity(0.2))
                                    .frame(width: 48, height: 48)
                                Image(systemName: selectedIcon)
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundStyle(colorFromString(selectedColor))
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(name.isEmpty ? "Preset Name" : name)
                                    .font(.headline)
                                Text("\(workMinutes)m work / \(breakMinutes)m break × \(cycles)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    }
                }
                .formStyle(.grouped)
                .scrollContentBackground(.hidden)
                .accentColor(.white)
            }
            
            // Footer
            HStack(spacing: 12) {
                Spacer()
                
                Button("Save Preset") {
                    savePreset()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty)
            }
            .padding()
            .background(Color.cardBackground)
        }
        .frame(width: 400, height: 580)
        .background(Color.appBackground)
        .foregroundStyle(Color.textPrimary)
        .environment(\.colorScheme, .dark)
    }
    
    private func savePreset() {
        let newPreset = TimerPreset(
            id: preset?.id ?? UUID(),
            name: name,
            workDuration: TimeInterval(workMinutes * 60),
            breakDuration: TimeInterval(breakMinutes * 60),
            maxCycles: cycles,
            icon: selectedIcon,
            color: selectedColor,
            isBuiltIn: false
        )
        
        if preset == nil {
            presetManager.addPreset(newPreset)
        } else {
            presetManager.updatePreset(newPreset)
        }
        
        dismiss()
    }
    
    private func colorFromString(_ colorName: String) -> Color {
        switch colorName.lowercased() {
        case "red": return Color.statusError
        case "orange": return Color.accentOrange
        case "yellow": return Color.accentYellow
        case "green": return Color.accentGreen
        case "blue": return Color.accentBlue
        case "purple": return Color.accentPurple
        case "pink": return Color.accentOrange
        default: return Color.accentBlue
        }
    }
}

