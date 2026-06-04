import SwiftUI

public struct AppSelectionTile<Content: View>: View {
    @GitOKTheme private var theme
    @GitOKMotionPreferenceReader private var motionPreference

    let isSelected: Bool
    let cornerRadius: CGFloat
    let selectedScale: CGFloat
    let selectedBorderColor: Color?
    let action: () -> Void
    let content: Content

    @State private var isHovered = false

    public init(
        isSelected: Bool = false,
        cornerRadius: CGFloat = 8,
        selectedScale: CGFloat = 1,
        selectedBorderColor: Color? = nil,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.isSelected = isSelected
        self.cornerRadius = cornerRadius
        self.selectedScale = selectedScale
        self.selectedBorderColor = selectedBorderColor
        self.action = action
        self.content = content()
    }

    var resolvedBorderColor: Color {
        selectedBorderColor ?? theme.primary
    }

    var resolvedScale: CGFloat {
        isSelected ? selectedScale : 1
    }

    public var body: some View {
        Button(action: action) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .overlay(selectionBorder)
                .overlay(hoverBorder)
                .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
        .buttonStyle(.plain)
        .scaleEffect(resolvedScale)
        .animation(AppUI.Motion.enabled(AppUI.Motion.selection, preference: motionPreference), value: isSelected)
        .onHover { hovering in
            AppUI.Motion.animate(AppUI.Motion.enabled(AppUI.Motion.hover, preference: motionPreference)) {
                isHovered = hovering
            }
        }
    }

    @ViewBuilder private var selectionBorder: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(resolvedBorderColor, lineWidth: 2)
        }
    }

    @ViewBuilder private var hoverBorder: some View {
        if isHovered && isSelected == false {
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(theme.primary.opacity(0.25), lineWidth: 1)
        }
    }
}

#Preview {
    HStack(spacing: 12) {
        AppSelectionTile(isSelected: true, action: {}) {
            LinearGradient(colors: [.blue, .green], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        .frame(width: 60, height: 40)

        AppSelectionTile(action: {}) {
            LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        .frame(width: 60, height: 40)
    }
    .padding()
}
