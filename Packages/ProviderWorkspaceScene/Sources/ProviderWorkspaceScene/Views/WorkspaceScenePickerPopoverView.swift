import SwiftUI

/// 工作场景选择弹层：列出可用场景，当前场景高亮打勾。
///
/// 结构与样式对齐工具栏的分支选择弹层 `BranchPickerPopoverView` 列表部分：
/// - 每行 = 场景图标 + 场景名 + 当前场景的 checkmark；
/// - 当前场景行以 accentColor 背景高亮，点击其他场景切换并关闭弹层。
@MainActor
struct WorkspaceScenePickerPopoverView: View {
    @ObservedObject private var model: WorkspaceScenePickerModel
    /// 切换成功后由本视图置为 false，关闭工具栏按钮的弹层。
    let isPresented: Binding<Bool>

    init(model: WorkspaceScenePickerModel, isPresented: Binding<Bool>) {
        self.model = model
        self.isPresented = isPresented
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 2) {
                ForEach(model.availableScenes) { scene in
                    row(for: scene)
                }
            }
            .padding(8)
        }
        .frame(width: 220)
    }

    private func row(for scene: GitOKWorkspaceScene) -> some View {
        let isCurrent = scene == model.selectedScene
        return Button {
            model.select(scene)
            isPresented.wrappedValue = false
        } label: {
            HStack(spacing: 8) {
                Image(systemName: scene.systemImage)
                    .font(.system(size: 13))
                    .foregroundStyle(isCurrent ? Color.accentColor : Color.secondary)
                Text(scene.title)
                    .font(.system(size: 13))
                    .lineLimit(1)
                Spacer()
                if isCurrent {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isCurrent ? Color.accentColor.opacity(0.12) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}
