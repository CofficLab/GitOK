import GitOKCoreKit
import GitOKUI
import SwiftUI

public struct FileListToolbarView: View {
    @Binding private var filterText: String
    private let fileCount: Int
    private let isLoading: Bool
    private let showsDiscardAll: Bool
    private let onDiscardAll: () -> Void

    public init(
        filterText: Binding<String>,
        fileCount: Int,
        isLoading: Bool,
        showsDiscardAll: Bool,
        onDiscardAll: @escaping () -> Void
    ) {
        self._filterText = filterText
        self.fileCount = fileCount
        self.isLoading = isLoading
        self.showsDiscardAll = showsDiscardAll
        self.onDiscardAll = onDiscardAll
    }

    public var body: some View {
        VStack(spacing: 6) {
            HStack {
                if showsDiscardAll {
                    AppButton(
                        GitDetailLocalization.string("Discard All Changes"),
                        systemImage: "arrow.uturn.backward",
                        style: .destructive,
                        size: .small
                    ) {
                        onDiscardAll()
                    }
                    .help(GitDetailLocalization.string("Discard changes of all files"))
                }

                Spacer()

                if isLoading {
                    HStack(spacing: 4) {
                        AppSpinningIcon(size: 12)
                        Text(GitDetailLocalization.string("Loading..."))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.text")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12))

                        Text("\(fileCount) \(GitDetailLocalization.string("files"))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            AppSearchBar(
                text: $filterText,
                placeholder: Text(GitDetailLocalization.string("Filter files"))
                    .font(.caption)
            )
        }
        .padding(.horizontal, 3)
        .padding(.vertical, 6)
        .background(Color(NSColor.controlBackgroundColor))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(NSColor.separatorColor)),
            alignment: .bottom
        )
    }
}
