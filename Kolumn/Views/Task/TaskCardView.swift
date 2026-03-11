import SwiftUI

struct TaskCardView: View {
    let task: TaskItem
    let viewModel: BoardViewModel
    @Environment(\.appTheme) private var theme
    @Environment(AppState.self) private var appState
    @State private var showDetail = false

    var tagAccentColor: Color? {
        guard let firstTag = task.tags.first else { return nil }
        return Color(hex: firstTag.colorHex)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                Text(task.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(theme.primaryTextColor)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer()

                PriorityBadgeView(priority: task.priority)
            }

            if let dueDate = task.dueDate {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                    Text(dueDate, style: .date)
                        .font(.caption)
                }
                .foregroundStyle(dueDateColor(dueDate))
            }

            if !task.tags.isEmpty {
                FlowLayout(spacing: 4) {
                    ForEach(task.tags) { tag in
                        TagChipView(tag: tag)
                    }
                }
            }

            if !task.subtasks.isEmpty {
                let completed = task.subtasks.filter(\.isCompleted).count
                HStack(spacing: 4) {
                    Image(systemName: "checklist")
                        .font(.caption2)
                    Text("\(completed)/\(task.subtasks.count)")
                        .font(.caption)
                }
                .foregroundStyle(completed == task.subtasks.count ? theme.accentColor : theme.secondaryTextColor)
            }

            if !task.notes.isEmpty {
                Text(task.notes)
                    .font(.caption)
                    .foregroundStyle(theme.secondaryTextColor)
                    .lineLimit(2)
            }
        }
        .padding(10)
        .padding(.leading, tagAccentColor != nil ? 4 : 0)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.cardBackgroundColor)
        .overlay(alignment: .leading) {
            if let color = tagAccentColor {
                Rectangle()
                    .fill(color)
                    .frame(width: 4)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(theme.accentColor, lineWidth: 2)
                .opacity(appState.selectedTaskID == task.id ? 1 : 0)
        )
        .opacity(task.isArchived ? 0.5 : 1.0)
        .overlay(alignment: .topTrailing) {
            if task.isArchived {
                Text("Archived")
                    .font(.caption2)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(theme.secondaryTextColor.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .padding(6)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            showDetail = true
        }
        .onTapGesture {
            appState.selectedTaskID = task.id
        }
        .contextMenu {
            Button(task.isArchived ? "Unarchive" : "Archive") {
                if task.isArchived {
                    viewModel.unarchiveTask(task)
                } else {
                    viewModel.archiveTask(task)
                }
            }
            Divider()
            Button("Delete", role: .destructive) {
                viewModel.deleteTask(task)
            }
        }
        .sheet(isPresented: $showDetail) {
            TaskDetailView(task: task, viewModel: viewModel)
        }
    }

    private func dueDateColor(_ date: Date) -> Color {
        if date < .now {
            return .red
        } else if date < (Calendar.current.date(byAdding: .day, value: 2, to: .now) ?? .distantFuture) {
            return .orange
        }
        return theme.secondaryTextColor
    }
}

// Simple flow layout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    struct CacheData {
        var positions: [CGPoint] = []
        var size: CGSize = .zero
    }

    func makeCache(subviews: Subviews) -> CacheData {
        CacheData()
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout CacheData) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        cache.positions = result.positions
        cache.size = result.size
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout CacheData) {
        for (index, position) in cache.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            totalWidth = max(totalWidth, x - spacing)
            totalHeight = y + rowHeight
        }

        return (positions, CGSize(width: totalWidth, height: totalHeight))
    }
}
