import SwiftUI
import MagicCore

/**
    图标标签栏视图
    水平展示所有项目中的图标项，点击切换当前选中图标。
**/
struct IconTabsBar: View {
    /// 图标数据源
    /// - 用途: 提供需要展示的所有图标
    /// - 类型: [IconData]
    let icons: [IconData]

    /// 当前选中的图标
    /// - 用途: 反映外部当前选中图标并支持切换
    /// - 类型: Binding<IconData?>
    @Binding var selection: IconData?

    var body: some View {
        HStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(icons) { icon in
                        Button(action: { selection = icon }) {
                            HStack(spacing: 6) {
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 14, height: 14)
                                    .padding(4)
                                    .background(Color.gray.opacity(0.15))
                                    .cornerRadius(4)

                                Text(icon.title)
                                    .font(.callout)
                                    .lineLimit(1)
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(isSelected(icon) ? Color.accentColor.opacity(0.15) : Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isSelected(icon) ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: isSelected(icon) ? 1 : 0.5)
                            )
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            BtnDelIcon(icon: icon)
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
            .frame(height: 40)

            BtnCreate()
                .frame(height: 32)
                .frame(width: 32)
                .padding(8)
        }
    }

    private func isSelected(_ icon: IconData) -> Bool {
        selection?.path == icon.path
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .setInitialTab(IconPlugin.label)
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .hideProjectActions()
            .hideTabPicker()
            .setInitialTab(IconPlugin.label)
            .hideSidebar()
    }
    .frame(width: 800)
    .frame(height: 1200)
}


