import SwiftUI
import MagicCore

/**
 * 展示 Commit 详细信息的视图组件
 */
struct CommitDetailView: View {
    let commit: GitCommit
    @State private var isCopied: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Commit 图标
                Image(systemName: commit.isHead ? "circle.fill" : "smallcircle.filled.circle")
                    .foregroundColor(commit.isHead ? .green : .blue)
                    .font(.system(size: 12))
                
                // Commit 消息
                Text(commit.message)
                    .font(.headline)
                    .lineLimit(2)
                
                Spacer()
                
                // HEAD 标签
                if commit.isHead {
                    Text("HEAD")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(4)
                }
            }
            
            // 详细信息行
            if !commit.isHead {
                HStack(spacing: 16) {
                    // 作者信息
                    if !commit.author.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "person.circle")
                                .foregroundColor(.secondary)
                                .font(.system(size: 12))
                            Text(commit.author)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // 提交时间
                    if !commit.date.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .foregroundColor(.secondary)
                                .font(.system(size: 12))
                            Text(commit.date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                
                // Hash 信息
                if !commit.hash.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "number")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12))
                        Text(commit.hash.prefix(8))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)
                        
                        // 复制按钮
                        Button(action: {
                            commit.hash.copy()
                            withAnimation(.spring()) {
                                isCopied = true
                            }
                            
                            // 1.5秒后重置状态
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation(.spring()) {
                                    isCopied = false
                                }
                            }
                        }) {
                            Image(systemName: isCopied ? "checkmark.circle" : "doc.on.doc")
                                .font(.system(size: 10))
                                .foregroundColor(isCopied ? .green : .secondary)
                                .scaleEffect(isCopied ? 1.2 : 1.0)
                        }
                        .buttonStyle(.plain)
                        .help(isCopied ? "已复制" : "复制完整 Hash")
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(MagicBackground.orange.opacity(0.15))
    }
}

#Preview {
    VStack(spacing: 16) {
        // HEAD commit 预览
        CommitDetailView(commit: GitCommit(
            isHead: true,
            path: "/test",
            hash: "HEAD",
            message: "当前工作区"
        ))
        
        // 普通 commit 预览
        CommitDetailView(commit: GitCommit(
            isHead: false,
            path: "/test",
            hash: "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0",
            message: "feat: 添加新功能，支持用户登录和注册",
            author: "张三",
            date: "2024-01-15 14:30:25"
        ))
    }
    .padding()
    .frame(width: 400)
}

#Preview("App-Big Screen") {
    RootView {
        ContentView()
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
