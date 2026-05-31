import AppKit
import GitOKPluginKit
import SwiftUI

public struct FileInfoTile: View {
    @Environment(\.gitOKSelectedFilePath) private var selectedFilePath
    @Environment(\.gitOKProjectPath) private var projectPath

    @State private var isPopoverPresented = false

    public init() {}

    public var body: some View {
        if let selectedFilePath, selectedFilePath.isEmpty == false {
            Button {
                isPopoverPresented.toggle()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 11, weight: .semibold))
                    pathComponentsView(for: selectedFilePath)
                }
                .padding(.horizontal, 8)
                .frame(height: 24)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(selectedFilePath)
            .popover(isPresented: $isPopoverPresented) {
                popoverContent
            }
        }
    }

    private func pathComponentsView(for filePath: String) -> some View {
        HStack(spacing: 4) {
            let components = FileInfoPathPresentation.displayComponents(for: filePath)
            ForEach(Array(components.enumerated()), id: \.offset) { index, component in
                Text(component)
                    .font(.footnote.weight(index == components.count - 1 ? .semibold : .regular))
                    .foregroundStyle(index == components.count - 1 ? .primary : .secondary)
                    .lineLimit(1)

                if index < components.count - 1 {
                    Text(PluginFileInfoLocalization.string(">"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxHeight: .infinity)
    }

    private var popoverContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(PluginFileInfoLocalization.string("File Actions"))
                .font(.headline)
                .padding(.bottom, 4)

            Button {
                revealInFinder()
                isPopoverPresented = false
            } label: {
                Label(PluginFileInfoLocalization.string("Reveal in Finder"), systemImage: "finder")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                openInVSCode()
                isPopoverPresented = false
            } label: {
                Label(PluginFileInfoLocalization.string("Open in VS Code"), systemImage: "chevron.left.forwardslash.chevron.right")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                copyPath()
                isPopoverPresented = false
            } label: {
                Label(PluginFileInfoLocalization.string("Copy Path"), systemImage: "doc.on.doc")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .frame(width: 220)
    }

    private var targetFileURL: URL? {
        FileInfoPathPresentation.targetURL(projectPath: projectPath, filePath: selectedFilePath)
    }

    private func revealInFinder() {
        guard let url = targetFileURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    private func openInVSCode() {
        guard let url = targetFileURL else { return }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["open", "-a", "Visual Studio Code", url.path]
        try? process.run()
    }

    private func copyPath() {
        guard let url = targetFileURL else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(url.path, forType: .string)
    }
}
