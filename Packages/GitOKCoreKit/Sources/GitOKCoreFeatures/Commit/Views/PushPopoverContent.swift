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
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.regular)
            Text(CommitLocalization.string("Pushing..."))
                .font(.body)
                .foregroundColor(.secondary)
        }
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
                Button(CommitLocalization.string("Cancel")) {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)

                Button(pushError == nil ? CommitLocalization.string("Push") : CommitLocalization.string("Retry")) {
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
                .buttonStyle(.borderedProminent)
            }

            Spacer()
        }
    }

    private func errorView(_ error: Error) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text(CommitLocalization.string("Push failed"))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.red)
            }

            Text(CommitLocalization.string("Push failed: \(error.localizedDescription)"))
                .font(.caption)
                .foregroundColor(.red)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.red.opacity(0.1))
        .cornerRadius(6)
    }
}
