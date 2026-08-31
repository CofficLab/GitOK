import SwiftUI

public struct FileListRowBackgroundView: View {
    private let state: FileListRules.RowBackgroundState

    public init(isHovered: Bool) {
        self.state = FileListRules.rowBackgroundState(isHovered: isHovered)
    }

    public var body: some View {
        switch state {
        case .hovered:
            Color.accentColor.opacity(FileListRules.hoveredRowOpacity)
        case .clear:
            Color.clear
        }
    }
}
