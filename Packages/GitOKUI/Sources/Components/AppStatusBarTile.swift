import SwiftUI

public struct AppStatusBarTile<Content: View>: View {
    @GitOKTheme private var theme
    @GitOKMotionPreferenceReader private var motionPreference
    @State private var isHovered = false

    let systemImage: String?
    let tint: Color?
    let action: (() -> Void)?
    let content: Content

    public init(
        systemImage: String? = nil,
        tint: Color? = nil,
        action: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.systemImage = systemImage
        self.tint = tint
        self.action = action
        self.content = content()
    }

    public var body: some View {
        Group {
            if let action {
                Button(action: action) {
                    label
                }
                .buttonStyle(.plain)
            } else {
                label
            }
        }
        .onHover { hovering in
            AppUI.Motion.animate(AppUI.Motion.enabled(AppUI.Motion.hover, preference: motionPreference)) {
                isHovered = hovering
            }
        }
    }

    private var label: some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(tint ?? theme.textSecondary)
            }

            content
                .font(.footnote)
        }
        .padding(.horizontal, horizontalPadding)
        .frame(height: height)
        .frame(maxHeight: .infinity, alignment: .center)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .contentShape(Rectangle())
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(isHovered ? theme.primary.opacity(0.16) : Color.clear)
    }

    var height: CGFloat { 24 }
    var horizontalPadding: CGFloat { 8 }
    var cornerRadius: CGFloat { 4 }
}

public extension AppStatusBarTile where Content == EmptyView {
    init(
        systemImage: String? = nil,
        tint: Color? = nil,
        action: (() -> Void)? = nil
    ) {
        self.init(systemImage: systemImage, tint: tint, action: action) {
            EmptyView()
        }
    }
}
