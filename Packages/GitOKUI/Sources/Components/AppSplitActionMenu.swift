import SwiftUI

public struct AppSplitActionMenu<MenuContent: View>: View {
    @GitOKTheme private var theme
    @GitOKMotionPreferenceReader private var motionPreference
    @State private var isHovered = false

    private let title: String
    private let detail: String?
    private let systemImage: String
    private let showsTitle: Bool
    private let isLoading: Bool
    private let isDisabled: Bool
    private let action: () -> Void
    private let menuContent: () -> MenuContent

    public init(
        title: String,
        detail: String? = nil,
        systemImage: String,
        showsTitle: Bool = true,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void,
        @ViewBuilder menuContent: @escaping () -> MenuContent
    ) {
        self.title = title
        self.detail = detail
        self.systemImage = systemImage
        self.showsTitle = showsTitle
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
        self.menuContent = menuContent
    }

    public var body: some View {
        HStack(spacing: 1) {
            Button(action: action) {
                HStack(spacing: 8) {
                    if isLoading {
                        AppSpinningIcon(size: 14)
                            .transition(.opacity.combined(with: .scale(scale: 0.86)))
                    } else {
                        Image(systemName: systemImage)
                            .font(.system(size: 14, weight: .semibold))
                            .frame(width: 16, height: 16)
                            .transition(.opacity.combined(with: .scale(scale: 0.86)))
                    }

                    if showsTitle {
                        Text(title)
                            .font(DesignTokens.Typography.subheadline.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }

                    if let detail {
                        Text(detail)
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .lineLimit(1)
                            .contentTransition(.numericText())
                            .transition(.opacity.combined(with: .move(edge: .trailing)))
                    }
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .frame(height: 40)
                .frame(minWidth: showsTitle ? 150 : 76)
                .background(
                    UnevenRoundedRectangle(
                        topLeadingRadius: DesignTokens.Radius.sm,
                        bottomLeadingRadius: DesignTokens.Radius.sm,
                        bottomTrailingRadius: 3,
                        topTrailingRadius: 3,
                        style: .continuous
                    )
                    .fill(primaryFill)
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(isDisabled || isLoading)
            .accessibilityLabel(Text(title))

            Menu {
                menuContent()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.92))
                    .frame(width: 34, height: 40)
                    .background(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 3,
                            bottomLeadingRadius: 3,
                            bottomTrailingRadius: DesignTokens.Radius.sm,
                            topTrailingRadius: DesignTokens.Radius.sm,
                            style: .continuous
                        )
                        .fill(menuFill)
                    )
                    .contentShape(Rectangle())
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .disabled(isDisabled || isLoading)
        }
        .opacity(isDisabled ? 0.55 : 1)
        .scaleEffect(isHovered && !isDisabled && !isLoading && motionPreference.allowsMotion ? 1.015 : 1)
        .shadow(color: theme.primary.opacity(isHovered ? 0.18 : 0.10), radius: isHovered ? 8 : 4, y: isHovered ? 3 : 2)
        .animation(animation, value: title)
        .animation(animation, value: detail)
        .animation(animation, value: isLoading)
        .animation(animation, value: isHovered)
        .onHover { hovering in
            guard motionPreference.allowsMotion else {
                isHovered = hovering
                return
            }
            withAnimation(animation) {
                isHovered = hovering
            }
        }
    }

    private var primaryFill: Color {
        isHovered && !isDisabled && !isLoading
            ? theme.primary.opacity(0.86)
            : theme.primary.opacity(0.72)
    }

    private var menuFill: Color {
        isHovered && !isDisabled && !isLoading
            ? theme.primary.opacity(0.72)
            : theme.primary.opacity(0.56)
    }

    private var animation: Animation? {
        motionPreference.allowsMotion
            ? .easeInOut(duration: DesignTokens.Duration.standard)
            : nil
    }
}

#Preview {
    AppSplitActionMenu(
        title: "Pull origin",
        detail: "↑3 ↓1",
        systemImage: "arrow.down",
        action: {}
    ) {
        Button("Fetch") {}
        Button("Pull") {}
        Button("Push") {}
    }
    .padding()
}
