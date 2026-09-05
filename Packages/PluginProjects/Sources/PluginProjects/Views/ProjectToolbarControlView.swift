import LumiUI
import ProviderProjects
import SwiftUI
import UniformTypeIdentifiers

/// 工具栏项目控件：显示当前项目名称，点击弹出项目列表（Lumi 风格）。
public struct ProjectToolbarControlView: View {
    let projects: any ProjectProviding
    @StateObject private var observation: ProjectObservationModel
    @State private var isPopoverPresented = false
    @State private var isImporterPresented = false
    @State private var isHovering = false

    public init(projects: any ProjectProviding) {
        self.projects = projects
        _observation = StateObject(wrappedValue: ProjectObservationModel(projects: projects))
    }

    public var body: some View {
        Button {
            isPopoverPresented = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "folder")
                    .font(.system(size: 12, weight: .semibold))

                Text(projects.currentProject?.title ?? "Projects")
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)

                Image(systemName: isPopoverPresented ? "chevron.up" : "chevron.down")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHighlighted ? Color.secondary.opacity(0.15) : Color.secondary.opacity(0.07))
            )
        }
        .buttonStyle(.plain)
        .popover(isPresented: $isPopoverPresented, arrowEdge: .bottom) {
            ProjectToolbarPopoverView(projects: projects, requestImporter: presentImporter)
        }
        // Present the importer from the toolbar host rather than from the
        // popover. macOS can leave a SwiftUI fileImporter attached to an
        // NSPopover spinning while it tries to create the file panel.
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        .onHover { isHovering = $0 }
    }

    /// 控件是否应显示高亮（悬停或弹层已展开）。
    private var isHighlighted: Bool {
        isHovering || isPopoverPresented
    }

    private func presentImporter() {
        isPopoverPresented = false

        // Let the popover finish dismissing before the file importer asks the
        // main window to present its panel.
        Task { @MainActor in
            await Task.yield()
            isImporterPresented = true
        }
    }

    private func handleImport(_ result: Result<[URL], any Error>) {
        guard case let .success(urls) = result,
              let url = urls.first else {
            return
        }
        projects.addProject(at: url)
    }
}
