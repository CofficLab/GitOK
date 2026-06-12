import SwiftUI

public struct AppActionCard<Content: View>: View {
    @GitOKTheme private var theme
    @GitOKMotionPreferenceReader private var motionPreference

    let title: Text
    let systemImage: String
    let tint: Color
    let isDisabled: Bool
    let action: () -> Void
    let content: Content?

    @State private var isHovered = false

    public init(
        _ title: String,
        systemImage: String,
        tint: Color,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) where Content == EmptyView {
        self.title = Text(title)
        self.systemImage = systemImage
        self.tint = tint
        self.isDisabled = isDisabled
        self.action = action
        self.content = nil
    }

    public init(
        _ title: String,
        systemImage: String,
        tint: Color,
        isDisabled: Bool = false,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = Text(title)
        self.systemImage = systemImage
        self.tint = tint
        self.isDisabled = isDisabled
        self.action = action
        self.content = content()
    }

    public var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: systemImage)
                        .font(.title2)
                        .foregroundColor(isDisabled ? theme.textSecondary : tint)
                        .frame(width: 24)

                    title
                        .font(.headline)
                        .foregroundColor(isDisabled ? theme.textSecondary : theme.textPrimary)

                    Spacer()
                }

                if let content {
                    content
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .gitOKUISurface(
                style: .subtle,
                cornerRadius: 8,
                borderColor: isDisabled ? theme.textSecondary.opacity(0.20) : tint.opacity(isHovered ? 0.45 : 0.30),
                lineWidth: 1
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.65 : 1)
        .scaleEffect(isHovered && !isDisabled && motionPreference.allowsMotion ? AppUI.Motion.hoverScale : 1)
        .animation(AppUI.Motion.enabled(AppUI.Motion.hover, preference: motionPreference), value: isHovered)
        .onHover { hovering in
            AppUI.Motion.animate(AppUI.Motion.enabled(AppUI.Motion.hover, preference: motionPreference)) {
                isHovered = hovering && !isDisabled
            }
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        AppActionCard("Download", systemImage: "square.and.arrow.down", tint: .blue, action: {})
        AppActionCard("Disabled", systemImage: "xmark.circle", tint: .orange, isDisabled: true, action: {})
        AppActionCard("With Details", systemImage: "archivebox", tint: .green, action: {}) {
            VStack(alignment: .leading) {
                Text("Additional export details")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    .padding()
    .frame(width: 320)
}
