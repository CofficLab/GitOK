import MagicCore
import SwiftUI

struct CommitRow: View, SuperThread {
    let commit: GitCommit
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var tag: String = ""

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onSelect) {
                ZStack(alignment: .topTrailing) {
                    // 主要内容
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            // 第一行：提交消息
                            HStack {
                                Text(commit.message)
                                    .lineLimit(1)
                                    .font(.system(size: 13))
                                Spacer()
                            }

                            // 第二行：提交人和提交时间
                            if !commit.isHead {
                                HStack {
                                    Text(commit.author)
                                        .lineLimit(1)
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)

                                    Text(commit.date)
                                        .lineLimit(1)
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)

                                    Spacer()
                                }
                            }
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        .frame(minHeight: 25)
                        .contentShape(Rectangle())
                    }
                    
                    // 标签作为右上角背景
                    if !tag.isEmpty {
                        Text(tag)
                            .font(.system(size: 12))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(0)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            .onAppear(perform: loadTag)

            Divider()
        }
    }

    /// 异步加载commit的tag信息
    private func loadTag() {
        // 如果是HEAD，不需要加载tag
        if commit.isHead {
            return
        }

        bg.async {
            do {
                let tagResult = try commit.getTag()
                main.async {
                    self.tag = tagResult.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            } catch {
                // 获取tag失败时不显示tag
            }
        }
    }
}

#Preview {
    RootView {
        ContentView()
            .hideSidebar()
    }
    .frame(width: 800)
    .frame(height: 800)
}
