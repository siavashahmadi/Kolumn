import SwiftUI

struct TagChipView: View {
    let tag: Tag

    var body: some View {
        Text(tag.name)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color(hex: tag.colorHex).opacity(0.3))
            .foregroundStyle(Color(hex: tag.colorHex))
            .clipShape(Capsule())
    }
}
