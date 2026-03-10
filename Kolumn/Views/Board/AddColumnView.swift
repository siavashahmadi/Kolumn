import SwiftUI

struct AddColumnView: View {
    let viewModel: BoardViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @State private var columnTitle = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("New Column")
                .font(.headline)

            TextField("Column title", text: $columnTitle)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Add") {
                    let trimmed = columnTitle.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty {
                        viewModel.addColumn(title: trimmed)
                        dismiss()
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(columnTitle.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 300)
    }
}
