import AppKit
import LumiUI
import ProviderProjects
import SwiftUI

/// 文件信息 tile：显示当前选中文件路径，点击弹出文件操作
/// （对齐旧版 FileInfoTile）。
public struct FileInfoTile: View {
    let projects: any ProjectProviding
    @StateObject private var observation: ProjectObservationModel
    @State private var isPopoverPresented = false

    public init(projects: any ProjectProviding) {
        self.projects = projects
        _observation = StateObject(wrappedValue: ProjectObservationModel(projects: projects))
    }

    public var body: some View {
        Group {
            if let file = projects.currentFile, !file.isEmpty {
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
            Text(FileInfoLocalization.string("File Actions", bundle: .module))
                .font(.headline)
                .padding(.bottom, 4)
            Button {
                revealInFinder(file: file)
                isPopoverPresented = false
            } label: {
                Label(FileInfoLocalization.string("Reveal in Finder", bundle: .module), systemImage: "finder")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Button {
                copyText(file)
                isPopoverPresented = false
            } label: {
                Label(FileInfoLocalization.string("Copy Path", bundle: .module), systemImage: "doc.on.doc")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Button {
                openWithDefaultApp(file: file)
                isPopoverPresented = false
            } label: {
                Label(FileInfoLocalization.string("Open with Default App", bundle: .module), systemImage: "arrow.up.forward.app")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(12)
        .frame(width: 240)
    }

    private var projectURL: URL? {
        projects.currentProject?.url
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

/// 项目观察模型：订阅 `ProjectProviding` 事件。
@MainActor
final class ProjectObservationModel: ObservableObject {
    @Published private(set) var revision = 0
    private var handle: (any ProjectProvidingObserverHandle)?

    init(projects: any ProjectProviding) {
        handle = projects.addObserver { [weak self] _ in
            self?.revision += 1
        }
    }
}
