import MagicCore
import SwiftUI
import UniformTypeIdentifiers

/**
 * 图标制作器主视图
 * 负责显示图标预览和Favicon生成功能
 * App图标生成功能已移动到工具栏中
 */
struct IconMaker: View {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var m: MagicMessageProvider
    @EnvironmentObject var i: IconProvider

    @State private var icon: IconModel?

    var body: some View {
        Group {
            if self.icon != nil {
                HStack(spacing: 2) {
                    XcodeMaker(icon: icon!)
                        .frame(maxWidth: .infinity)

                    FaviconMaker(icon: icon!)
                        .frame(maxWidth: .infinity)
                }
                .padding()
            } else {
                Text("请选择或新建一个图标")
            }
        }
        .onAppear {
            self.icon = i.currentModel
        }
        .onNotification(.iconDidSave, perform: { _ in
            self.icon = i.currentModel
        })
        // 截图功能已移动到工具栏中，不再需要监听snapshotTapped状态
        .onChange(of: i.currentModel, {
            self.icon = i.currentModel
        })
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout().setInitialTab("Icon")
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 800)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout().setInitialTab("Icon")
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
