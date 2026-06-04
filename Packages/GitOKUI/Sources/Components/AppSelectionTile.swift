import SwiftUI

public struct AppSelectionTile<Content: View>: View {
    @GitOKTheme private var theme
    @GitOKMotionPreferenceReader private var motionPreference

    let isSelected: Bool
    let cornerRadius: CGFloat
    let selectedScale: CGFloat
    let selectedBackgroundColor: Color?
    let selectedBorderColor: Color?
    let selectedBorderWidth: CGFloat
    let idleBorderColor: Color?
    let idleBorderWidth: CGFloat
    let action: () -> Void
    let content: Content

    @State private var isHovered = false

    public init(
        isSelected: Bool = false,
        cornerRadius: CGFloat = 8,
        selectedScale: CGFloat = 1,
        selectedBackgroundColor: Color? = nil,
        selectedBorderColor: Color? = nil,
        selectedBorderWidth: CGFloat = 2,
        idleBorderColor: Color? = nil,
        idleBorderWidth: CGFloat = 0,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.isSelected = isSelected
        self.cornerRadius = cornerRadius
        self.selectedScale = selectedScale
        self.selectedBackgroundColor = selectedBackgroundColor
        self.selectedBorderColor = selectedBorderColor
        self.selectedBorderWidth = selectedBorderWidth
        self.idleBorderColor = idleBorderColor
        self.idleBorderWidth = idleBorderWidth
        self.action = action
        self.content = content()
    }

    var resolvedBorderColor: Color {
        selectedBorderColor ?? theme.primary
    }

    var resolvedScale: CGFloat {
        isSelected ? selectedScale : 1
    }

    var resolvedBorderWidth: CGFloat {
        isSelected ? selectedBorderWidth : idleBorderWidth
    }

    public var body: some View {
        Button(action: action) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(tileBackground)
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
                .stroke(resolvedBorderColor, lineWidth: selectedBorderWidth)
        } else if let idleBorderColor, idleBorderWidth > 0 {
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(idleBorderColor, lineWidth: idleBorderWidth)
        }
    }

    @ViewBuilder private var hoverBorder: some View {
        if isHovered && isSelected == false {
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(theme.primary.opacity(0.25), lineWidth: 1)
        }
    }

    @ViewBuilder private var tileBackground: some View {
        if isSelected, let selectedBackgroundColor {
            selectedBackgroundColor
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
