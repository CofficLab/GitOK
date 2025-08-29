import MagicCore
import SwiftUI

/**
 * 仓库来源选择标签页组件
 * 负责显示所有可用的图标来源（使用各自自定义名称），支持切换不同的来源
 * 顶部水平排列的标签页
 */
struct SourceTabs: View {
    @Binding var selectedSourceName: String?
    let availableSources: [IconSourceProtocol]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(availableSources, id: \.sourceName) { source in
                    SourceTab(
                        title: source.sourceName,
                        isSelected: selectedSourceName == source.sourceName,
                        isAvailable: true
                    ) {
                        selectedSourceName = source.sourceName
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .background(Color(.windowBackgroundColor))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.separatorColor)),
            alignment: .bottom
        )
    }
}

/**
 * 单个仓库来源标签组件
 * 显示来源名称和可用状态，支持点击选择
 */
struct SourceTab: View {
    let title: String
    let isSelected: Bool
    let isAvailable: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? .accentColor : (isAvailable ? .primary : .secondary))
                
                // 选中状态指示器
                Rectangle()
                    .frame(height: 2)
                    .foregroundColor(isSelected ? .accentColor : .clear)
            }
            .frame(height: 40)
            .padding(.horizontal, 16)
            .background(
                Rectangle()
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isAvailable)
        .opacity(isAvailable ? 1.0 : 0.5)
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout().setInitialTab(IconPlugin.label)
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout().setInitialTab(IconPlugin.label)
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
