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
            Text("\(String(localized: "Selected")) \(selectedCount)")
                .font(.caption)
                .foregroundColor(.secondary)
                .monospacedDigit()

            Button(String(localized: "Stage"), action: onStage)
                .disabled(canStage == false)
                .keyboardShortcut("s", modifiers: [.command, .shift])
                .accessibilityHint(String(localized: "Stage files that can still be staged in the batch selection"))

            Button(String(localized: "Unstage"), action: onUnstage)
                .disabled(canUnstage == false)
                .keyboardShortcut("u", modifiers: [.command, .shift])
                .accessibilityHint(String(localized: "Unstage already staged files in the batch selection"))

            Button(String(localized: "Discard"), role: .destructive, action: onDiscard)
                .disabled(canDiscard == false)
                .keyboardShortcut(.delete, modifiers: [.command])
                .accessibilityHint(String(localized: "Discard changes of files in the batch selection"))

            Spacer()

            Button(String(localized: "Select All Current"), action: onSelectAll)
                .disabled(canSelectAll == false)
                .keyboardShortcut("a", modifiers: [.command, .shift])
                .accessibilityHint(String(localized: "Select all files in the current filter result"))

            Button(String(localized: "Clear Selection"), action: onClearSelection)
                .accessibilityHint(String(localized: "Clear current batch selection"))
        }
        .font(.caption)
        .buttonStyle(.borderless)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.accentColor.opacity(0.08))
        )
    }
}
