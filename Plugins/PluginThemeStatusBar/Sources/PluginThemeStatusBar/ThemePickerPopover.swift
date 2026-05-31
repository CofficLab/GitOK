import GitOKUI
import SwiftUI

struct ThemePickerPopover: View {
    let registry: GitOKUIThemeRegistry
    let selectTheme: (String) -> Void

    init(registry: GitOKUIThemeRegistry, selectTheme: @escaping (String) -> Void) {
        self.registry = registry
        self.selectTheme = selectTheme
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            if registry.themes.isEmpty {
                GitOKUI.AppEmptyState(
                    icon: "paintbrush",
                    title: "No themes available"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(registry.themes) { theme in
                            themeRow(theme)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .frame(height: 420)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "paintbrush")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(registry.selectedContribution?.iconColor ?? .accentColor)

            Text("Theme")
                .font(.system(size: 13, weight: .semibold))

            Spacer()
        }
    }

    private func themeRow(_ theme: GitOKUIThemeContribution) -> some View {
        let isSelected = theme.id == registry.selectedThemeId

        return GitOKUI.AppListRow(isSelected: isSelected, action: {
            selectTheme(theme.id)
        }) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(theme.iconColor.opacity(isSelected ? 0.24 : 0.14))
                        .frame(width: 26, height: 26)

                    Image(systemName: theme.iconName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(theme.iconColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(theme.displayName)
                        .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                        .foregroundColor(.primary)

                    Text(theme.description)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                HStack(spacing: 4) {
                    Circle()
                        .fill(theme.chromeTheme.accentColors().primary)
                    Circle()
                        .fill(theme.chromeTheme.accentColors().secondary)
                    Circle()
                        .fill(theme.chromeTheme.accentColors().tertiary)
                }
                .frame(width: 34, height: 10)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(theme.iconColor)
                }
            }
        }
    }
}
