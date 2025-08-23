import MagicCore
import SwiftUI
import UniformTypeIdentifiers

/**
 * 图标制作器主视图
 * 负责显示图标预览和多种格式的下载功能
 * 采用水平布局：左侧显示图标预览，右侧提供下载选项
 */
struct IconMaker: View {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var m: MagicMessageProvider
    @EnvironmentObject var i: IconProvider

    @State private var icon: IconModel?

    var body: some View {
        Group {
            if let icon = self.icon {
                HStack(spacing: 24) {
                    // 左侧：图标预览区域
                    IconPreview(icon: icon)
                        .frame(maxWidth: .infinity)
                    
                    // 右侧：下载按钮区域
                    DownloadButtons(icon: icon)
                        .frame(maxWidth: .infinity)
                }
                .padding()
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "photo")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("请选择或新建一个图标")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("选择一个图标后，您可以预览不同尺寸的效果并下载多种格式")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .onAppear {
            self.icon = i.currentModel
        }
        .onNotification(.iconDidSave, perform: { _ in
            self.icon = i.currentModel
        })
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
