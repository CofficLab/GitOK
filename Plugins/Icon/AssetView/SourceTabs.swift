import MagicCore
import SwiftUI

/**
 * 仓库来源选择标签页组件
 * 负责显示所有可用的图标来源，支持切换不同的来源类型
 * 顶部水平排列的标签页，显示本地、远程等不同来源
 */
struct SourceTabs: View {
    @Binding var selectedSourceType: IconSourceType
    let availableSources: [IconSourceProtocol]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(IconSourceType.allCases, id: \.self) { sourceType in
                    SourceTab(
                        sourceType: sourceType,
                        isSelected: selectedSourceType == sourceType,
                        isAvailable: availableSources.contains { $0.sourceType == sourceType }
                    ) {
                        selectedSourceType = sourceType
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
 * 显示来源类型名称和可用状态，支持点击选择
 */
struct SourceTab: View {
    let sourceType: IconSourceType
    let isSelected: Bool
    let isAvailable: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(sourceType.displayName)
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
