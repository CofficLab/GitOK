import SwiftUI
import MagicCore

/**
 * 自定义图片按钮组件
 * 提供更换图标图片的功能
 * 放置在下载区域上方
 */
struct CustomImageButton: View {
    @EnvironmentObject var iconProvider: IconProvider
    @EnvironmentObject var m: MagicMessageProvider
    
    var body: some View {
        VStack(spacing: 8) {
            // 标题
            Text("自定义图片")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // 换图按钮
            Button(action: changeImage) {
                VStack(spacing: 4) {
                    Image.add
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    Text("更换图片")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            .buttonStyle(.plain)
            .help("选择新的图片文件")
            .disabled(iconProvider.currentData == nil)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private func changeImage() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.image]
        panel.message = "选择新的图片文件"
        panel.prompt = "选择图片"
        
        if panel.runModal() == .OK, let url = panel.url {
            do {
                if var icon = iconProvider.currentData {
                    try icon.updateImageURL(url)
                    m.success("图片已更新")
                } else {
                    m.error("没有找到可以更新的图标")
                }
            } catch {
                m.error("更新图片失败：\(error.localizedDescription)")
            }
        }
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
            .setInitialTab(IconPlugin.label)
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
