import SwiftUI

struct AddTaskPopoverView: View {
    let viewModel: BoardViewModel
    @Binding var isPresented: Bool
    @Environment(\.appTheme) private var theme
    @State private var taskTitle = ""
    @State private var selectedColumn: Column?
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 12) {
            Text("Add Task")
                .font(.headline)
                .foregroundStyle(theme.primaryTextColor)

            Picker("Column", selection: $selectedColumn) {
                ForEach(viewModel.sortedColumns) { column in
                    Text(column.title).tag(Optional(column))
                }
            }
            .pickerStyle(.menu)

            TextField("Task title", text: $taskTitle)
                .textFieldStyle(.roundedBorder)
                .focused($isFocused)
                .onSubmit { addTask() }

            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Add") {
                    addTask()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(taskTitle.trimmingCharacters(in: .whitespaces).isEmpty || selectedColumn == nil)
            }
        }
        .padding(16)
        .frame(width: 280)
        .onAppear {
            selectedColumn = viewModel.sortedColumns.first
            isFocused = true
        }
    }

    private func addTask() {
        let trimmed = taskTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, let column = selectedColumn else { return }
        viewModel.addTask(title: trimmed, to: column)
        taskTitle = ""
        isFocused = true
    }
}
