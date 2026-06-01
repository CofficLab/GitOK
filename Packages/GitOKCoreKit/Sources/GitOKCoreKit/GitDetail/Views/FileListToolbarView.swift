import SwiftUI

public struct FileListToolbarView: View {
    @Binding private var filterText: String
    private let fileCount: Int
    private let isLoading: Bool
    private let showsDiscardAll: Bool
    private let onDiscardAll: () -> Void

    @State private var discardButtonHovered = false

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
                    Button(action: onDiscardAll) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 12))
                            Text(String(localized: "Discard All Changes"))
                                .font(.caption)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(discardButtonHovered ? Color.red.opacity(0.15) : Color.clear)
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(discardButtonHovered ? .white : .red)
                    .help(String(localized: "Discard changes of all files"))
                    .onHover { hovering in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            discardButtonHovered = hovering
                        }
                    }
                }

                Spacer()

                if isLoading {
                    HStack(spacing: 4) {
                        ProgressView()
                            .controlSize(.small)
                        Text(String(localized: "Loading..."))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.text")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12))

                        Text("\(fileCount) \(String(localized: "files"))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                TextField(String(localized: "Filter files"), text: $filterText)
                    .textFieldStyle(.plain)
                    .font(.caption)

                if filterText.isEmpty == false {
                    Button {
                        filterText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help(String(localized: "Clear filter"))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(NSColor.textBackgroundColor).opacity(0.75))
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
