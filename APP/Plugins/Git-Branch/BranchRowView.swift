import MagicKit
import LibGit2Swift
import SwiftUI

struct BranchRowView: View {
    let branch: GitBranch
    let isSelected: Bool
    let onSwitch: () -> Void

    var onDelete: (() -> Void)?

    @State private var showDeleteAlert = false
    
    var body: some View {
        HStack {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .accentColor : .secondary)
                .font(.system(size: 12))
            
            Text(branch.name)
                .font(.system(size: 13))
                .foregroundColor(isSelected ? .primary : .secondary)
            
            Spacer()
            
            if !isSelected {
                HStack(spacing: 8) {
                    Image.checkmark.inButtonWithAction {
                        onSwitch()
                    }

                    if onDelete != nil {
                        Image.trash.inButtonWithAction {
                            showDeleteAlert = true
                        }
                    }
                }
            } else {
                Text("当前", tableName: "GitBranch")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .cornerRadius(4)
        .alert("确认删除分支", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                onDelete?()
            }
        } message: {
            Text("确定要删除本地分支 \"\(branch.name)\" 吗？未合并的分支会由 Git 阻止删除。")
        }
    }
}
