import SwiftUI
import MagicCore

struct CommitRow: View, SuperThread {
    let commit: GitCommit
    let isSelected: Bool
    let onSelect: () -> Void
    
    @State private var tag: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: onSelect) {
                HStack {
                    Text(commit.message)
                        .lineLimit(1)
                        .font(.system(size: 13))
                    Spacer()
                    
                    if !tag.isEmpty {
                        Text(tag)
                            .font(.system(size: 11))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .frame(height: 25)
                .contentShape(Rectangle())
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
