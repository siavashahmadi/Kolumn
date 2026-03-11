import SwiftUI

struct AddColumnView: View {
    let viewModel: BoardViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @State private var columnTitle = ""
    @State private var selectedColor = "#C3B1E1"

    // Uses ColumnView.presetColors to avoid duplication

    var body: some View {
        VStack(spacing: 16) {
            Text("New Column")
                .font(.headline)

            TextField("Column title", text: $columnTitle)
                .textFieldStyle(.roundedBorder)

            VStack(alignment: .leading, spacing: 6) {
                Text("Color")
                    .font(.subheadline)
                    .foregroundStyle(theme.secondaryTextColor)
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(28), spacing: 6), count: 5), spacing: 6) {
                    ForEach(ColumnView.presetColors, id: \.self) { hex in
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 28, height: 28)
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.primary, lineWidth: selectedColor == hex ? 2 : 0)
                            )
                            .onTapGesture {
                                selectedColor = hex
                            }
                    }
                }
            }

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Add") {
                    let trimmed = columnTitle.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty {
                        viewModel.addColumn(title: trimmed, colorHex: selectedColor)
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
