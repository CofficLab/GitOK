import MagicCore
import os
import SwiftUI

struct IconAssetList: View {
    @EnvironmentObject var i: IconProvider
    @EnvironmentObject var m: MagicMessageProvider
    @EnvironmentObject var app: AppProvider

    @State var gridItems: [GridItem] = Array(repeating: .init(.flexible()), count: 10)

    var body: some View {
        VStack(spacing: 0) {
            // 分类标签页
            CategoryTabs()
            
            // 图标网格
            GeometryReader { geo in
                ScrollView {
                    VStack {
                        if let category = i.selectedCategory.isEmpty ? i.availableCategories.first : i.selectedCategory {
                            CategoryIconGrid(
                                category: category,
                                gridItems: gridItems,
                                onIconSelected: { selectedIconId in
                                    handleIconSelection(selectedIconId)
                                }
                            )
                        } else {
                            Text("没有可用的图标分类")
                                .foregroundColor(.secondary)
                                .padding()
                        }
                    }
                    .onAppear {
                        gridItems = getGridItems(geo)
                    }
                    .onChange(of: geo.size.width) {
                        gridItems = getGridItems(geo)
                    }
                }
            }
        }
    }

    func getGridItems(_ geo: GeometryProxy) -> [GridItem] {
        Array(repeating: .init(.flexible()), count: calculateColumns(geo.size.width))
    }

    func calculateColumns(_ width: CGFloat) -> Int {
        let columns = Int(width / 80)
        return max(columns, 1)
    }
    
    private func handleIconSelection(_ iconId: Int) {
        // 使用IconProvider的统一方法选择图标
        i.selectIcon(iconId)
        
        // 处理图标选择通知
        NotificationCenter.default.post(
            name: Notification.Name("IconSelected"),
            object: nil,
            userInfo: ["iconId": iconId]
        )
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
