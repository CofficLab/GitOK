import GitOKCoreKit
import GitOKUI
import SwiftUI

public struct FileBatchActionBarView: View {
    private let selectedCount: Int
    private let canStage: Bool
    private let canUnstage: Bool
    private let canDiscard: Bool
    private let canSelectAll: Bool
    private let onStage: () -> Void
    private let onUnstage: () -> Void
    private let onDiscard: () -> Void
    private let onSelectAll: () -> Void
    private let onClearSelection: () -> Void

    public init(
        selectedCount: Int,
        canStage: Bool,
        canUnstage: Bool,
        canDiscard: Bool,
        canSelectAll: Bool,
        onStage: @escaping () -> Void,
        onUnstage: @escaping () -> Void,
        onDiscard: @escaping () -> Void,
        onSelectAll: @escaping () -> Void,
        onClearSelection: @escaping () -> Void
    ) {
        self.selectedCount = selectedCount
        self.canStage = canStage
        self.canUnstage = canUnstage
        self.canDiscard = canDiscard
        self.canSelectAll = canSelectAll
        self.onStage = onStage
        self.onUnstage = onUnstage
        self.onDiscard = onDiscard
        self.onSelectAll = onSelectAll
        self.onClearSelection = onClearSelection
    }

    public var body: some View {
        HStack(spacing: 8) {
            Text("\(GitDetailLocalization.string("Selected")) \(selectedCount)")
                .font(.caption)
                .foregroundColor(.secondary)
                .monospacedDigit()

            AppButton(
                GitDetailLocalization.string("Stage"),
                systemImage: "plus.rectangle.on.folder",
                style: .secondary,
                size: .small,
                action: onStage
            )
                .disabled(canStage == false)
                .keyboardShortcut("s", modifiers: [.command, .shift])
                .accessibilityHint(GitDetailLocalization.string("Stage files that can still be staged in the batch selection"))

            AppButton(
                GitDetailLocalization.string("Unstage"),
                systemImage: "minus.rectangle",
                style: .secondary,
                size: .small,
                action: onUnstage
            )
                .disabled(canUnstage == false)
                .keyboardShortcut("u", modifiers: [.command, .shift])
                .accessibilityHint(GitDetailLocalization.string("Unstage already staged files in the batch selection"))

            AppButton(
                GitDetailLocalization.string("Discard"),
                systemImage: "trash",
                style: .destructive,
                size: .small,
                action: onDiscard
            )
                .disabled(canDiscard == false)
                .keyboardShortcut(.delete, modifiers: [.command])
                .accessibilityHint(GitDetailLocalization.string("Discard changes of files in the batch selection"))

            Spacer()

            AppButton(
                GitDetailLocalization.string("Select All Current"),
                systemImage: "checklist",
                style: .secondary,
                size: .small,
                action: onSelectAll
            )
                .disabled(canSelectAll == false)
                .keyboardShortcut("a", modifiers: [.command, .shift])
                .accessibilityHint(GitDetailLocalization.string("Select all files in the current filter result"))

            AppButton(
                GitDetailLocalization.string("Clear Selection"),
                systemImage: "xmark.circle",
                style: .ghost,
                size: .small,
                action: onClearSelection
            )
                .accessibilityHint(GitDetailLocalization.string("Clear current batch selection"))
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.accentColor.opacity(0.08))
        )
    }
}
