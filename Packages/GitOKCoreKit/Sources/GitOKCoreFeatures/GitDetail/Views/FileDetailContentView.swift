import AppKit
import SwiftUI

public struct FileDetailContentView: View {
    private let filePath: String
    private let isImage: Bool
    private let isBinary: Bool
    private let changeType: String
    private let diffText: String
    private let issueMessage: String?
    private let beforeImage: NSImage?
    private let afterImage: NSImage?
    @Binding private var imageDiffMode: GitDetailImageDiffMode
    @Binding private var imageBlendAmount: Double
    private let onRefresh: () -> Void
    private let onCopyRawDiff: () -> Void
    private let onShowBeforeText: () -> Void
    private let onShowAfterText: () -> Void
    private let onCopyReason: () -> Void

    public init(
        filePath: String,
        isImage: Bool,
        isBinary: Bool,
        changeType: String,
        diffText: String,
        issueMessage: String?,
        beforeImage: NSImage?,
        afterImage: NSImage?,
        imageDiffMode: Binding<GitDetailImageDiffMode>,
        imageBlendAmount: Binding<Double>,
        onRefresh: @escaping () -> Void,
        onCopyRawDiff: @escaping () -> Void,
        onShowBeforeText: @escaping () -> Void,
        onShowAfterText: @escaping () -> Void,
        onCopyReason: @escaping () -> Void
    ) {
        self.filePath = filePath
        self.isImage = isImage
        self.isBinary = isBinary
        self.changeType = changeType
        self.diffText = diffText
        self.issueMessage = issueMessage
        self.beforeImage = beforeImage
        self.afterImage = afterImage
        _imageDiffMode = imageDiffMode
        _imageBlendAmount = imageBlendAmount
        self.onRefresh = onRefresh
        self.onCopyRawDiff = onCopyRawDiff
        self.onShowBeforeText = onShowBeforeText
        self.onShowAfterText = onShowAfterText
        self.onCopyReason = onCopyReason
    }

    public var body: some View {
        VStack(spacing: 0) {
            FileDetailHeaderView(path: filePath, systemImage: presentationState.fileIcon)

            if isBinary {
                binaryFileView
            } else {
                diffContentView
            }
        }
    }

    private var presentationState: GitDetailDiffDisplayRules.FileDetailPresentationState {
        GitDetailDiffDisplayRules.fileDetailPresentationState(
            isImage: isImage,
            isBinary: isBinary,
            changeType: changeType,
            diffText: diffText
        )
    }

    @ViewBuilder
    private var diffContentView: some View {
        FileDiffContentView(mode: presentationState.diffContentMode) {
            emptyDiffView
        } largeContent: {
            largeDiffView
        } renderContent: {
            UnifiedDiffTextView(diffText: diffText)
        }
    }

    @ViewBuilder
    private var binaryFileView: some View {
        if isImage {
            ImageDiffContentView(
                displayMode: presentationState.imageDisplayMode,
                before: beforeImage,
                after: afterImage,
                mode: $imageDiffMode,
                blendAmount: $imageBlendAmount
            )
        } else {
            BinaryFilePlaceholderView()
        }
    }

    private var largeDiffView: some View {
        LargeDiffPlaceholderView(
            characterCount: diffText.count,
            canShowBeforeText: presentationState.canShowBeforeText,
            canShowAfterText: presentationState.canShowAfterText,
            onCopyRawDiff: onCopyRawDiff,
            onShowBeforeText: onShowBeforeText,
            onShowAfterText: onShowAfterText
        )
    }

    private var emptyDiffView: some View {
        EmptyDiffPlaceholderView(
            changeType: changeType,
            issueMessage: issueMessage,
            canShowBeforeText: presentationState.canShowBeforeText,
            canShowAfterText: presentationState.canShowAfterText,
            onRefresh: onRefresh,
            onShowBeforeText: onShowBeforeText,
            onShowAfterText: onShowAfterText,
            onCopyReason: onCopyReason
        )
    }
}

private struct UnifiedDiffTextView: View {
    let diffText: String

    var body: some View {
        ScrollView([.vertical, .horizontal]) {
            Text(diffText)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
        }
        .background(.background)
    }
}
