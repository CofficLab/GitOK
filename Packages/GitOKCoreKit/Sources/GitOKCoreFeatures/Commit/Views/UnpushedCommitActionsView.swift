import SwiftUI

public struct UnpushedCommitActionsView: View {
    private let canUndo: Bool
    @Binding private var showPushPopover: Bool
    @Binding private var isPushing: Bool
    @Binding private var pushError: Error?
    private let onUndo: () -> Void
    private let onPush: () async throws -> Void

    public init(
        canUndo: Bool,
        showPushPopover: Binding<Bool>,
        isPushing: Binding<Bool>,
        pushError: Binding<Error?>,
        onUndo: @escaping () -> Void,
        onPush: @escaping () async throws -> Void
    ) {
        self.canUndo = canUndo
        self._showPushPopover = showPushPopover
        self._isPushing = isPushing
        self._pushError = pushError
        self.onUndo = onUndo
        self.onPush = onPush
    }

    public var body: some View {
        HStack(spacing: 4) {
            if canUndo {
                Button(action: onUndo) {
                    Image(systemName: "arrow.uturn.backward.circle")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .help(String(localized: "Undo this commit"))
            }

            Button {
                showPushPopover = true
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.orange)
            }
            .buttonStyle(.plain)
            .help(String(localized: "Click to push to remote"))
            .popover(isPresented: $showPushPopover) {
                PushPopoverContent(
                    isPushing: $isPushing,
                    pushError: $pushError,
                    onPush: onPush,
                    onCancel: {
                        showPushPopover = false
                        pushError = nil
                    }
                )
            }
        }
    }
}
