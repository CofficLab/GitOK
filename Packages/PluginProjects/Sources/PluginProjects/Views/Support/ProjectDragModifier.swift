import SwiftUI

/// 项目行的拖拽修饰器。
///
/// 只有手动排序（`isEnabled == true`）时才挂上拖放行为：其他展示方式里
/// 列表顺序由规则决定，拖拽改变的是「手动顺序」却不会立刻反映到界面上，
/// 会让用户困惑。
struct ProjectDragModifier: ViewModifier {
    /// 是否启用拖拽。
    let isEnabled: Bool
    /// 当前行对应的项目 id。
    let projectID: UUID
    /// 正在被拖动的项目 id（拖动开始时写入）。
    @Binding var draggedProjectID: UUID?
    /// 拖放落位时的回调：把被拖动项目移动到目标项目之前。
    let onMove: (UUID, UUID?) -> Void

    @ViewBuilder
    func body(content: Content) -> some View {
        if isEnabled {
            content
                .onDrag {
                    draggedProjectID = projectID
                    return NSItemProvider(object: NSString(string: projectID.uuidString))
                }
                .onDrop(
                    of: [.text],
                    delegate: ProjectDropDelegate(
                        draggedProjectID: draggedProjectID,
                        targetProjectID: projectID,
                        onMove: onMove
                    )
                )
        } else {
            content
        }
    }
}
