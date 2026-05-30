import SwiftUI

/// Commit action button used by the app-level commit workflow.
public struct CommitSubmitButton: View {
    private let title: String
    private let systemImage: String
    private let action: () -> Void

    public init(
        _ title: String,
        systemImage: String = "arrow.up.circle",
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .labelStyle(.titleAndIcon)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.regular)
    }
}
