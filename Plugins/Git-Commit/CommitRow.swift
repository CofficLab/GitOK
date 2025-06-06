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

                                    // 相对时间标签
                                    Text(relativeTime(from: commit.date))
                                        .font(.system(size: 10))
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(4)
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
    
    /// 计算相对时间
    /// @param dateString 日期字符串
    /// @return 相对时间描述（如：2分钟前、3小时前、1天前等）
    private func relativeTime(from dateString: String) -> String {
        // Git 日期格式通常是 "YYYY-MM-DD HH:mm:ss" 或 ISO 8601 格式
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        // 尝试多种日期格式
        var date: Date?
        
        // 尝试标准格式
        date = formatter.date(from: dateString)
        
        // 如果失败，尝试 ISO 8601 格式
        if date == nil {
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            date = formatter.date(from: dateString)
        }
        
        // 如果还是失败，尝试其他常见格式
        if date == nil {
            formatter.dateFormat = "EEE MMM d HH:mm:ss yyyy Z"
            date = formatter.date(from: dateString)
        }
        
        guard let commitDate = date else {
            return "未知"
        }
        
        let now = Date()
        let timeInterval = now.timeIntervalSince(commitDate)
        
        if timeInterval < 60 {
            return "刚刚"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)分钟前"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)小时前"
        } else if timeInterval < 2592000 {
            let days = Int(timeInterval / 86400)
            return "\(days)天前"
        } else if timeInterval < 31536000 {
            let months = Int(timeInterval / 2592000)
            return "\(months)个月前"
        } else {
            let years = Int(timeInterval / 31536000)
            return "\(years)年前"
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

#Preview("App-Big Screen") {
    RootView {
        ContentView()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
