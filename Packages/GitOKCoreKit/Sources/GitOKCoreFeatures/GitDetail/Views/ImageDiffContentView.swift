import AppKit
import SwiftUI

public struct ImageDiffContentView: View {
    private let displayMode: GitDetailDiffDisplayRules.ImageDisplayMode
    private let before: NSImage?
    private let after: NSImage?
    @Binding private var mode: GitDetailImageDiffMode
    @Binding private var blendAmount: Double

    public init(
        displayMode: GitDetailDiffDisplayRules.ImageDisplayMode,
        before: NSImage?,
        after: NSImage?,
        mode: Binding<GitDetailImageDiffMode>,
        blendAmount: Binding<Double>
    ) {
        self.displayMode = displayMode
        self.before = before
        self.after = after
        self._mode = mode
        self._blendAmount = blendAmount
    }

    public var body: some View {
        switch displayMode {
        case .new:
            ImagePreviewSectionView(
                title: GitDetailDiffDisplayRules.imagePreviewTitle(for: .new),
                image: after
            )
        case .deleted:
            ImagePreviewSectionView(
                title: GitDetailDiffDisplayRules.imagePreviewTitle(for: .deleted),
                image: before
            )
        case .comparison:
            ImageComparisonView(
                before: before,
                after: after,
                mode: $mode,
                blendAmount: $blendAmount
            )
        }
    }
}
