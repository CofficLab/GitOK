import SwiftUI
import GitOKCoreKit
import GitOKUI

struct ThemePickerPopover: View {
    let registry: GitOKUIThemeRegistry
    let selectTheme: (String) -> Void
    
    @State private var selectedFilter: ThemeAppearanceKind? = nil

    init(registry: GitOKUIThemeRegistry, selectTheme: @escaping (String) -> Void) {
        self.registry = registry
        self.selectTheme = selectTheme
    }
    
    private var filteredThemes: [GitOKUIThemeContribution] {
        guard let filter = selectedFilter else {
            return registry.themes
        }
        return registry.themes.filter { $0.chromeTheme.appearanceKind == filter }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            
            filterTabs

            if filteredThemes.isEmpty {
                AppEmptyState(
                    icon: "paintbrush",
                    title: selectedFilter == nil ? "No themes available" : "No \(filterLabel(selectedFilter!)) themes"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(filteredThemes) { theme in
                            themeRow(theme)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .frame(height: 460)
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
    
    private var filterTabs: some View {
        HStack(spacing: 6) {
            filterTab(
                label: "All",
                icon: "square.grid.2x2",
                filter: nil,
                count: registry.themes.count
            )
            
            filterTab(
                label: "Dark",
                icon: "moon.fill",
                filter: .dark,
                count: registry.themes.filter { $0.chromeTheme.appearanceKind == .dark }.count
            )
            
            filterTab(
                label: "Light",
                icon: "sun.max.fill",
                filter: .light,
                count: registry.themes.filter { $0.chromeTheme.appearanceKind == .light }.count
            )
            
            filterTab(
                label: "Adaptive",
                icon: "circle.lefthalf.filled",
                filter: .system,
                count: registry.themes.filter { $0.chromeTheme.appearanceKind == .system }.count
            )
        }
        .padding(.horizontal, -4)
    }
    
    private func filterTab(label: String, icon: String, filter: ThemeAppearanceKind?, count: Int) -> some View {
        let isSelected = selectedFilter == filter
        
        return Button(action: {
            selectedFilter = filter
        }) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                
                Text(label)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                
                Text("\(count)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Color.clear : Color.secondary.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func filterLabel(_ kind: ThemeAppearanceKind) -> String {
        switch kind {
        case .dark: return "dark"
        case .light: return "light"
        case .system: return "adaptive"
        }
    }

    private func themeRow(_ theme: GitOKUIThemeContribution) -> some View {
        let isSelected = theme.id == registry.selectedThemeId

        return AppListRow(isSelected: isSelected, action: {
            selectTheme(theme.id)
        }) {
            HStack(spacing: 10) {
                ZStack {
                    Color.clear
                        .frame(width: 26, height: 26)
                        .gitOKUISurface(
                            style: .custom(theme.iconColor.opacity(isSelected ? 0.24 : 0.14)),
                            cornerRadius: 5
                        )

                    Image(systemName: theme.iconName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(theme.iconColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(theme.displayName)
                            .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                            .foregroundColor(.primary)
                        
                        appearanceBadge(theme.chromeTheme.appearanceKind)
                    }

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
    
    private func appearanceBadge(_ kind: ThemeAppearanceKind) -> some View {
        Group {
            switch kind {
            case .dark:
                Image(systemName: "moon.fill")
                    .foregroundColor(.purple.opacity(0.7))
            case .light:
                Image(systemName: "sun.max.fill")
                    .foregroundColor(.orange.opacity(0.7))
            case .system:
                Image(systemName: "circle.lefthalf.filled")
                    .foregroundColor(.blue.opacity(0.7))
            }
        }
        .font(.system(size: 9))
    }
}
