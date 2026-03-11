import SwiftUI
import SwiftData

struct TaskDetailView: View {
    let task: TaskItem
    let viewModel: BoardViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @Environment(\.modelContext) private var modelContext
    @State private var title: String
    @State private var notes: String
    @State private var priority: Priority
    @State private var dueDate: Date
    @State private var hasDueDate: Bool
    @State private var showTagManager = false
    @State private var newSubtaskTitle = ""
    @State private var selectedReminder: ReminderOffset?
    @Environment(NotificationManager.self) private var notificationManager: NotificationManager?
    @Query(sort: \Tag.name) private var allTags: [Tag]

    init(task: TaskItem, viewModel: BoardViewModel) {
        self.task = task
        self.viewModel = viewModel
        _title = State(initialValue: task.title)
        _notes = State(initialValue: task.notes)
        _priority = State(initialValue: task.priority)
        _dueDate = State(initialValue: task.dueDate ?? .now)
        _hasDueDate = State(initialValue: task.dueDate != nil)
        _selectedReminder = State(initialValue: task.reminderOffset.flatMap { ReminderOffset(rawValue: $0) })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Edit Task")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("Done") {
                    saveChanges()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }

            Divider()

            // Title
            TextField("Task title", text: $title)
                .textFieldStyle(.roundedBorder)
                .font(.title3)

            // Priority
            HStack {
                Text("Priority")
                    .foregroundStyle(theme.secondaryTextColor)
                Spacer()
                Picker("Priority", selection: $priority) {
                    ForEach(Priority.allCases) { p in
                        Text(p.label).tag(p)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 240)
            }

            // Due date
            HStack {
                Toggle("Due date", isOn: $hasDueDate)
                    .foregroundStyle(theme.secondaryTextColor)
                if hasDueDate {
                    DatePicker("", selection: $dueDate, displayedComponents: .date)
                        .labelsHidden()
                }
            }

            // Reminder
            if hasDueDate && (notificationManager?.isAuthorized ?? false) {
                HStack {
                    Text("Reminder")
                        .foregroundStyle(theme.secondaryTextColor)
                    Spacer()
                    Picker("Reminder", selection: $selectedReminder) {
                        Text("None").tag(nil as ReminderOffset?)
                        ForEach(ReminderOffset.allCases) { offset in
                            Text(offset.label).tag(offset as ReminderOffset?)
                        }
                    }
                    .frame(width: 200)
                }
            }

            // Tags
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Tags")
                        .foregroundStyle(theme.secondaryTextColor)
                    Spacer()
                    Button("Manage Tags", systemImage: "tag") {
                        showTagManager = true
                    }
                    .font(.caption)
                }

                FlowLayout(spacing: 6) {
                    ForEach(allTags) { tag in
                        TagToggleChip(tag: tag, isSelected: task.tags.contains(where: { $0.id == tag.id })) {
                            toggleTag(tag)
                        }
                    }
                }
            }

            // Subtasks
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Subtasks")
                        .foregroundStyle(theme.secondaryTextColor)
                    Spacer()
                    if !task.subtasks.isEmpty {
                        let completed = task.subtasks.filter(\.isCompleted).count
                        Text("\(completed)/\(task.subtasks.count)")
                            .font(.caption)
                            .foregroundStyle(theme.secondaryTextColor)
                    }
                }

                let sortedSubtasks = task.subtasks.sorted { $0.sortOrder < $1.sortOrder }
                ForEach(sortedSubtasks) { subtask in
                    HStack(spacing: 8) {
                        Button {
                            viewModel.toggleSubtask(subtask)
                        } label: {
                            Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(subtask.isCompleted ? theme.accentColor : theme.secondaryTextColor)
                        }
                        .buttonStyle(.plain)

                        Text(subtask.title)
                            .strikethrough(subtask.isCompleted)
                            .foregroundStyle(subtask.isCompleted ? theme.secondaryTextColor : theme.primaryTextColor)

                        Spacer()

                        Button {
                            viewModel.deleteSubtask(subtask, from: task)
                        } label: {
                            Image(systemName: "xmark")
                                .font(.caption2)
                                .foregroundStyle(theme.secondaryTextColor)
                        }
                        .buttonStyle(.plain)
                    }
                }

                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.caption)
                        .foregroundStyle(theme.secondaryTextColor)
                    TextField("Add subtask", text: $newSubtaskTitle)
                        .textFieldStyle(.plain)
                        .font(.callout)
                        .onSubmit {
                            let trimmed = newSubtaskTitle.trimmingCharacters(in: .whitespaces)
                            if !trimmed.isEmpty {
                                viewModel.addSubtask(title: trimmed, to: task)
                                newSubtaskTitle = ""
                            }
                        }
                }
            }

            // Notes
            VStack(alignment: .leading, spacing: 4) {
                Text("Notes")
                    .foregroundStyle(theme.secondaryTextColor)
                TextEditor(text: $notes)
                    .font(.body)
                    .frame(minHeight: 100)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(theme.cardBackgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(theme.accentColor.opacity(0.3))
                    )
            }

            Divider()

            // Footer actions
            HStack {
                Button("Delete Task", role: .destructive) {
                    viewModel.deleteTask(task)
                    dismiss()
                }
                .foregroundStyle(.red)

                Button(task.isArchived ? "Unarchive" : "Archive") {
                    if task.isArchived {
                        viewModel.unarchiveTask(task)
                    } else {
                        viewModel.archiveTask(task)
                    }
                    dismiss()
                }

                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
        }
        .padding(24)
        .frame(width: 480, height: 560)
        .sheet(isPresented: $showTagManager) {
            TagManagerSheet(modelContext: modelContext)
        }
    }

    private func saveChanges() {
        task.title = title.trimmingCharacters(in: .whitespaces).isEmpty ? task.title : title
        task.notes = notes
        task.priority = priority
        task.dueDate = hasDueDate ? dueDate : nil
        task.reminderOffset = selectedReminder?.rawValue

        // Handle notification scheduling
        if hasDueDate, let reminder = selectedReminder {
            notificationManager?.scheduleReminder(for: task, reminderOffset: reminder)
        } else {
            notificationManager?.cancelReminder(for: task)
        }

        try? modelContext.save()
    }

    private func toggleTag(_ tag: Tag) {
        if let index = task.tags.firstIndex(where: { $0.id == tag.id }) {
            task.tags.remove(at: index)
        } else {
            task.tags.append(tag)
        }
        try? modelContext.save()
    }
}

struct TagToggleChip: View {
    let tag: Tag
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.appTheme) private var theme

    var body: some View {
        Button(action: action) {
            Text(tag.name)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isSelected ? Color(hex: tag.colorHex) : Color(hex: tag.colorHex).opacity(0.2))
                .foregroundStyle(isSelected ? .white : theme.primaryTextColor)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct TagManagerSheet: View {
    let modelContext: ModelContext
    @Environment(\.dismiss) private var dismiss
    @State private var tagName = ""
    @State private var tagColor = "#FFB3A7"
    @State private var tagViewModel: TagViewModel?

    private let presetColors = ["#FFB3A7", "#A7D8FF", "#B5EAD7", "#FFE066", "#C3B1E1", "#FFD1DC"]

    var body: some View {
        VStack(spacing: 16) {
            Text("Manage Tags")
                .font(.headline)

            HStack {
                TextField("Tag name", text: $tagName)
                    .textFieldStyle(.roundedBorder)

                HStack(spacing: 4) {
                    ForEach(presetColors, id: \.self) { color in
                        Circle()
                            .fill(Color(hex: color))
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle().stroke(tagColor == color ? Color.primary : Color.clear, lineWidth: 2)
                            )
                            .onTapGesture { tagColor = color }
                    }
                }

                Button("Add") {
                    guard !tagName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    tagViewModel?.addTag(name: tagName, colorHex: tagColor)
                    tagName = ""
                }
                .disabled(tagName.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            if let tagViewModel {
                List {
                    ForEach(tagViewModel.tags) { tag in
                        HStack {
                            Circle()
                                .fill(Color(hex: tag.colorHex))
                                .frame(width: 12, height: 12)
                            Text(tag.name)
                            Spacer()
                            Button(role: .destructive) {
                                tagViewModel.deleteTag(tag)
                            } label: {
                                Image(systemName: "trash")
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(height: 150)
            }

            Button("Done") { dismiss() }
                .keyboardShortcut(.defaultAction)
        }
        .padding(20)
        .frame(width: 420, height: 350)
        .onAppear {
            tagViewModel = TagViewModel(modelContext: modelContext)
        }
    }
}
