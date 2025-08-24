import SwiftUI
import MagicCore

/**
 * 分类图标项组件
 * 负责显示单个图标，支持选中状态、悬停效果和点击事件
 * 数据流：IconAsset -> UI展示
 */
struct IconView: View {
    let iconAsset: IconAsset
    
    @EnvironmentObject var iconProvider: IconProvider
    @State private var image = Image(systemName: "photo")
    @State private var isHovered = false
    @State private var isLoading = false
    @State private var hasError = false
    
    /// 判断当前图标是否被选中
    private var isSelected: Bool {
        iconProvider.selectedIconId == iconAsset.iconId
    }
    
    var body: some View {
        Group {
            if isLoading {
                // 加载状态
                ProgressView()
                    .frame(width: 40, height: 40)
            } else if hasError {
                // 错误状态
                Image(systemName: "exclamationmark.triangle")
                    .font(.title2)
                    .foregroundColor(.red)
                    .frame(width: 40, height: 40)
            } else {
                // 正常显示
                image
                    .resizable()
                    .frame(width: 40, height: 40)
            }
        }
        .background(
            Group {
                if isSelected {
                    // 选中状态：蓝色背景
                    Color.accentColor.opacity(0.3)
                } else if isHovered {
                    // 悬停状态：浅色背景
                    Color.accentColor.opacity(0.1)
                } else {
                    // 默认状态：透明背景
                    Color.clear
                }
            }
        )
        .overlay(
            // 选中状态显示蓝色边框
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .cornerRadius(8)
        .onTapGesture {
            if !isLoading && !hasError {
                self.iconProvider.selectIcon(iconAsset.iconId)
            }
        }
        .onHover { hovering in
            isHovered = hovering
        }
        .onAppear {
            loadIconImage()
        }
    }
    
    private func loadIconImage() {
        switch iconAsset.source {
        case .local:
            // 本地图标直接加载
            DispatchQueue.global().async {
                let thumbnail = iconAsset.getThumbnail()
                DispatchQueue.main.async {
                    self.image = thumbnail
                }
            }
            
        case .remote:
            // 远程图标异步加载
            loadRemoteIcon()
        }
    }
    
    /// 加载远程图标
    private func loadRemoteIcon() {
        guard let remotePath = iconAsset.remotePath else {
            hasError = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                let iconURL = IconRepo.shared.getIconURL(for: remotePath)
                guard let url = iconURL else {
                    await MainActor.run {
                        hasError = true
                        isLoading = false
                    }
                    return
                }
                
                let (data, response) = try await URLSession.shared.data(from: url)
                
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    await MainActor.run {
                        hasError = true
                        isLoading = false
                    }
                    return
                }
                
                await MainActor.run {
                    // 检查文件类型
                    let fileExtension = remotePath.lowercased()
                    
                    if fileExtension.hasSuffix(".svg") {
                        // 对于SVG文件，尝试显示SVG内容
                        if let nsImage = NSImage(data: data) {
                            self.image = Image(nsImage: nsImage)
                        } else {
                            self.image = Image(systemName: "doc.text")
                        }
                    } else if let nsImage = NSImage(data: data) {
                        self.image = Image(nsImage: nsImage)
                    } else {
                        // 根据文件类型显示不同的占位符
                        if fileExtension.hasSuffix(".png") {
                            self.image = Image(systemName: "photo")
                        } else if fileExtension.hasSuffix(".jpg") || fileExtension.hasSuffix(".jpeg") {
                            self.image = Image(systemName: "camera")
                        } else if fileExtension.hasSuffix(".gif") {
                            self.image = Image(systemName: "play.circle")
                        } else if fileExtension.hasSuffix(".webp") {
                            self.image = Image(systemName: "globe")
                        } else {
                            self.image = Image(systemName: "doc")
                        }
                    }
                    
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
