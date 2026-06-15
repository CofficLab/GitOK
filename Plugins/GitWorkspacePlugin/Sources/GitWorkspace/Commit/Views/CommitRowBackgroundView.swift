import SwiftUI

public struct CommitRowBackgroundView: View {
    private let state: CommitRowAppearanceRules.BackgroundState

    public init(isSelected: Bool, isHovered: Bool) {
        self.state = CommitRowAppearanceRules.backgroundState(
            isSelected: isSelected,
            isHovered: isHovered
        )
    }

    public var body: some View {
        switch state {
        case .selected:
            Color.accentColor.opacity(CommitRowAppearanceRules.selectedOpacity)
        case .hovered:
            Color.primary.opacity(CommitRowAppearanceRules.hoveredOpacity)
        case .clear:
            Color.clear
        }
    }
}
