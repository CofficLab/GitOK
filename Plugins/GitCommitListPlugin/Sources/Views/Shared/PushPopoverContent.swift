import GitOKCoreKit
import GitOKUI
import SwiftUI

/// Popover content for pushing an unpushed commit.
public struct PushPopoverContent: View {
    @Binding private var isPushing: Bool
    @Binding private var pushError: Error?
    private let onPush: () async throws -> Void
    private let onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss

    public init(
        isPushing: Binding<Bool>,
        pushError: Binding<Error?>,
        onPush: @escaping () async throws -> Void,
        onCancel: @escaping () -> Void
    ) {
        self._isPushing = isPushing
        self._pushError = pushError
        self.onPush = onPush
        self.onCancel = onCancel
    }

    public var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundColor(.orange)
                Text(CommitLocalization.string("Push to Remote"))
                    .font(.headline)
                Spacer()
            }

            Divider()

            if isPushing {
                pushingState
            } else {
                readyState
            }
        }
        .padding(16)
        .frame(width: 280, height: pushError != nil ? 200 : (isPushing ? 160 : 180))
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var pushingState: some View {
        AppLoadingOverlay(message: CommitLocalization.string("Pushing..."))
        .frame(minHeight: 60)
    }

    private var readyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.orange)
                Text(CommitLocalization.string("Current commit has not been pushed to remote"))
                    .font(.body)
            }

            if let error = pushError {
                errorView(error)
            }

            HStack(spacing: 12) {
                AppButton(
                    CommitLocalization.string("Cancel"),
                    style: .secondary,
                    size: .small
                ) {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)

                AppButton(
                    pushError == nil ? CommitLocalization.string("Push") : CommitLocalization.string("Retry"),
                    systemImage: pushError == nil ? "arrow.up.circle" : "arrow.clockwise",
                    style: .primary,
                    size: .small,
                    isLoading: isPushing
                ) {
                    Task {
                        do {
                            isPushing = true
                            pushError = nil
                            try await onPush()
                            dismiss()
                        } catch {
                            isPushing = false
                            pushError = error
                        }
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(isPushing)
            }

            Spacer()
        }
    }

    private func errorView(_ error: Error) -> some View {
        AppErrorBanner(message: CommitLocalization.string("Push failed: \(error.localizedDescription)"))
    }
}
