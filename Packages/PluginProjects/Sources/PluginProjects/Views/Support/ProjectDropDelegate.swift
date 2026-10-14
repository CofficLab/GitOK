import SwiftUI

/// 将拖放目标转换为项目 ID 移动操作。
///
/// 侧边栏行与列表尾部共用这一个 delegate：拖到某一行表示插到它之前，
/// 拖到尾部占位区域表示插到分组末尾。
struct ProjectDropDelegate: DropDelegate {
    let draggedProjectID: UUID?
    let targetProjectID: UUID?
    let onMove: (UUID, UUID?) -> Void

    func dropEntered(info: DropInfo) {
        guard let draggedProjectID, draggedProjectID != targetProjectID else { return }
        onMove(draggedProjectID, targetProjectID)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        true
    }
}
