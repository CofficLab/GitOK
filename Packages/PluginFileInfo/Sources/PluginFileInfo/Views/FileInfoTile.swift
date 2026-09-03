import AppKit
import LumiUI
import ProviderCommit
import SwiftUI

/// 文件信息 tile：显示当前选中文件路径，点击弹出文件操作
/// （对齐旧版 FileInfoTile）。
public struct FileInfoTile: View {
    let commit: any CommitDetailProviding
    @StateObject private var observation: CommitObservationModel
    @State private var isPopoverPresented = false

    public init(commit: any CommitDetailProviding) {
        self.commit = commit
        _observation = StateObject(wrappedValue: CommitObservationModel(commit: commit))
    }

    public var body: some View {
        Group {
            if let file = commit.selectedFile, !file.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 10))
                    pathComponentsView(file)
                }
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    isPopoverPresented.toggle()
                }
                .help(file)
                .popover(isPresented: $isPopoverPresented, arrowEdge: .bottom) {
                    popoverContent(file: file)
                }
            }
        }
        .onReceive(observation.$revision) { _ in }
    }

    private func pathComponentsView(_ path: String) -> some View {
        HStack(spacing: 3) {
            let components = path.split(separator: "/").map(String.init)
            ForEach(Array(components.enumerated()), id: \.offset) { index, component in
                Text(component)
                    .font(.appCaption)
                    .fontWeight(index == components.count - 1 ? .semibold : .regular)
                    .foregroundStyle(index == components.count - 1 ? theme.textPrimary : theme.textSecondary)
                    .lineLimit(1)
                if index < components.count - 1 {
                    Text(">")
                        .font(.appCaption)
                        .foregroundStyle(theme.textTertiary)
                }
            }
        }
    }

    private func popoverContent(file: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("File Actions")
                .font(.headline)
                .padding(.bottom, 4)
            Button {
                revealInFinder(file: file)
                isPopoverPresented = false
            } label: {
                Label("Reveal in Finder", systemImage: "finder")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Button {
                copyText(file)
                isPopoverPresented = false
            } label: {
                Label("Copy Path", systemImage: "doc.on.doc")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Button {
                openWithDefaultApp(file: file)
                isPopoverPresented = false
            } label: {
                Label("Open with Default App", systemImage: "arrow.up.forward.app")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(12)
        .frame(width: 240)
    }

    private var projectURL: URL? {
        commit.selectedProjectURL
    }

    private func revealInFinder(file: String) {
        guard let url = projectURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url.appendingPathComponent(file)])
    }

    private func openWithDefaultApp(file: String) {
        guard let url = projectURL else { return }
        NSWorkspace.shared.open(url.appendingPathComponent(file))
    }

    private func copyText(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    @LumiTheme private var theme: LumiUITheme
}

/// 提交详情观察模型：订阅 `CommitDetailProviding` 事件。
@MainActor
final class CommitObservationModel: ObservableObject {
    @Published private(set) var revision = 0
    private var handle: (any CommitDetailObserverHandle)?

    init(commit: any CommitDetailProviding) {
        handle = commit.addObserver { [weak self] _ in
            self?.revision += 1
        }
    }
}
