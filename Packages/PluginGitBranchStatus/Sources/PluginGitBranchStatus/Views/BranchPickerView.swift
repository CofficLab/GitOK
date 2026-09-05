import KitGit
import LumiUI
import ProviderProjects
import SwiftUI

/// 工具栏分支选择器：显示当前分支名，点击弹出分支选择弹层。
///
/// 视觉与交互对齐工具栏中间的项目管理控件 `ProjectToolbarControlView`：
/// - 图标 + 分支名 + chevron 的胶囊按钮，圆角背景随悬停 / 展开高亮；
/// - 点击弹出 `popover`（而非原生 Menu），弹层内容为
///   `BranchPickerPopoverView`（搜索 + 新建 + 分支列表，对齐项目管理弹层）；
/// - 无项目 / 非 git 仓库时显示 "No Branch" 并禁用点击。
public struct BranchPickerView: View {
    let projects: any ProjectProviding
    @StateObject private var observation: ProjectObservationModel
    @State private var currentBranch: String?
    @State private var isLoading = false
    @State private var isPopoverPresented = false
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
                Image(systemName: "arrow.triangle.branch")
                    .font(.system(size: 12, weight: .semibold))

                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text(currentBranch ?? "No Branch")
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

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
        .disabled(projects.currentProject == nil)
        .popover(isPresented: $isPopoverPresented, arrowEdge: .bottom) {
            BranchPickerPopoverView(projects: projects, isPresented: $isPopoverPresented)
        }
        .onHover { isHovering = $0 }
        .onAppear { load() }
        .onReceive(observation.$revision) { _ in load() }
        .onReceive(observation.$lastEvent) { event in
            if case .dataChanged = event {
                load()
            }
        }
        .help("Switch Branch")
    }

    /// 控件是否应显示高亮（悬停或弹层已展开）。
    private var isHighlighted: Bool {
        isHovering || isPopoverPresented
    }

    @MainActor
    private func load() {
        guard let url = projects.currentProject?.url else {
            currentBranch = nil
            isLoading = false
            return
        }
        isLoading = true
        Task.detached(priority: .utility) {
            let current = GitRefReader.currentBranch(in: url)
            await MainActor.run {
                currentBranch = current
                isLoading = false
            }
        }
    }
}
