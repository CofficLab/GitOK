import SwiftUI
import OSLog
import MagicCore

/**
    候选图标列表中的单个图标项
 */
struct IconItem: View, SuperLog {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var i: IconProvider
    @EnvironmentObject var m: MagicMessageProvider
    
    static var emoji = "🐒"

    @State var image = Image("icon")

    var selected: Bool {
        i.selectedIconId == iconId
    }

    var iconId: Int
    var category: String = "" // 新增分类参数，默认为空以兼容旧版本

    var body: some View {
        image
            .resizable()
            .frame(height: 80)
            .frame(width: 80)
            .background(selected ? Color.brown.opacity(0.1) : Color.clear)
            .onTapGesture {
                // 使用IconProvider的统一方法选择图标
                i.selectIcon(iconId)
            }
            .onAppear {
                DispatchQueue.global().async {
                    let thumbnail: Image
                    if !category.isEmpty {
                        // 使用新的分类方法
                        thumbnail = IconPng.getThumbnail(category: category, iconId: iconId)
                    } else {
                        // 兼容旧版本
                        thumbnail = IconPng.getThumbnail(iconId)
                    }
                    
                    DispatchQueue.main.async {
                        self.image = thumbnail
                    }
                }
            }
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 800)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
