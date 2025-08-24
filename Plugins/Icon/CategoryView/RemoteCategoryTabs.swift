import SwiftUI
import MagicCore

/**
 * 远程分类标签页组件
 * 负责显示远程图标分类，支持异步加载和错误处理
 * 数据流：IconRepo -> RemoteIconCategory List
 */
struct RemoteCategoryTabs: View {
    @State private var remoteCategories: [RemoteIconCategory] = []
    @State private var isLoading: Bool = true
    @State private var hasError: Bool = false
    @EnvironmentObject var iconProvider: IconProvider
    
    var body: some View {
        Group {
            if isLoading {
                // 加载状态
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("加载中...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            } else if hasError {
                // 错误状态
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.red)
                    Text("加载失败")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            } else {
                // 正常显示分类标签
                ForEach(remoteCategories, id: \.id) { category in
                    RemoteCategoryTab(category: category)
                }
            }
        }
        .onAppear {
            loadRemoteCategories()
        }
    }
    
    /// 加载远程分类
    private func loadRemoteCategories() {
        Task {
            do {
                let allCategories = await IconRepo.shared.getAllCategories()
                let categories = allCategories.filter { $0.source == .remote }.compactMap { $0.remoteCategory }
                await MainActor.run {
                    remoteCategories = categories
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    hasError = true
                    isLoading = false
                }
            }
        }
    }
}

/**
 * 远程分类标签组件
 * 负责显示单个远程分类，支持选中状态和点击事件
 */
struct RemoteCategoryTab: View {
    let category: RemoteIconCategory
    
    @EnvironmentObject var iconProvider: IconProvider
    
    /// 判断当前分类是否被选中
    private var isSelected: Bool {
        iconProvider.selectedRemoteCategoryId == category.id
    }
    
    var body: some View {
        Button(action: {
            selectRemoteCategory()
        }) {
            VStack(spacing: 4) {
                Text(category.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                Text("\(category.iconCount)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
            .foregroundColor(isSelected ? .accentColor : .primary)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    /// 选择远程分类
    private func selectRemoteCategory() {
        iconProvider.selectRemoteCategory(category.id)
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .setInitialTab("Icon")
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .setInitialTab("Icon")
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
