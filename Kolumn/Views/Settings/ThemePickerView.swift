import SwiftUI

struct ThemePickerView: View {
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        @Bindable var themeManager = themeManager

        VStack(alignment: .leading, spacing: 16) {
            Text("Choose a Theme")
                .font(.title2)
                .fontWeight(.semibold)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 16)], spacing: 16) {
                ForEach(AppTheme.all) { theme in
                    ThemeSwatchView(
                        theme: theme,
                        isSelected: themeManager.current.id == theme.id
                    ) {
                        themeManager.current = theme
                    }
                }
            }

            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ThemeSwatchView: View {
    let theme: AppTheme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(theme.backgroundColor)
                    .frame(height: 60)
                    .overlay {
                        HStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(theme.columnHeaderColor)
                                .frame(width: 30, height: 40)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(theme.cardBackgroundColor)
                                .frame(width: 30, height: 40)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(theme.accentColor)
                                .frame(width: 30, height: 40)
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? theme.accentColor : .clear, lineWidth: 3)
                    )

                Text(theme.name)
                    .font(.caption)
                    .fontWeight(isSelected ? .bold : .regular)
            }
        }
        .buttonStyle(.plain)
    }
}
