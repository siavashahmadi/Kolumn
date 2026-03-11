import SwiftUI

struct PriorityBadgeView: View {
    let priority: Priority
    @State private var isPulsing = false

    private var color: Color {
        switch priority {
        case .low: .green
        case .medium: .orange
        case .high: .red
        }
    }

    var body: some View {
        Text(priority.label)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
            .scaleEffect(priority == .high && isPulsing ? 1.08 : 1.0)
            .animation(
                priority == .high
                    ? .easeInOut(duration: 1.2).repeatForever(autoreverses: true)
                    : .default,
                value: isPulsing
            )
            .onAppear {
                if priority == .high {
                    isPulsing = true
                }
            }
    }
}
