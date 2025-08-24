import MagicCore
import SwiftUI
import UniformTypeIdentifiers

/**
 * 图标下载按钮组件
 * 提供多种格式的图标下载功能
 * 支持PNG、SVG、Favicon等格式
 */
struct DownloadButtons: View {
    let icon: IconData
    
    @EnvironmentObject var iconProvider: IconProvider
    @State private var isGenerating = false
    @State private var currentIconAsset: IconAsset?
    
    var body: some View {
        VStack(spacing: 16) {
            Text("下载选项")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                // PNG格式下载
                Button("下载 PNG 格式") {
                    Task {
                        await downloadPNG()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isGenerating || currentIconAsset == nil)
                
                // Favicon下载
                Button("下载 Favicon") {
                    Task {
                        await downloadFavicon()
                    }
                }
                .buttonStyle(.bordered)
                .disabled(isGenerating || currentIconAsset == nil)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .onAppear {
            loadCurrentIconAsset()
        }
        .onChange(of: iconProvider.selectedIconId) { _, _ in
            loadCurrentIconAsset()
        }
    }
    
    // MARK: - 私有方法
    
    private func loadCurrentIconAsset() {
        guard !iconProvider.selectedIconId.isEmpty else {
            currentIconAsset = nil
            return
        }
        
        Task {
            if let iconAsset = await IconRepo.shared.getIconAsset(byId: iconProvider.selectedIconId) {
                await MainActor.run {
                    self.currentIconAsset = iconAsset
                }
            } else {
                await MainActor.run {
                    self.currentIconAsset = nil
                }
            }
        }
    }
    
    // MARK: - 下载方法
    
    @MainActor private func downloadPNG() async {
        guard let iconAsset = currentIconAsset else {
            MagicMessageProvider.shared.error("没有可用的图标资源")
            return
        }
        
        isGenerating = true
        defer { isGenerating = false }
        
        let tag = Date.nowCompact
        let folderName = "PNG-\(tag)"
        
        guard let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
            MagicMessageProvider.shared.error("无权访问下载文件夹")
            return
        }
        
        let folderPath = downloadsURL.appendingPathComponent(folderName, isDirectory: true)
        
        do {
            try FileManager.default.createDirectory(at: folderPath, withIntermediateDirectories: true)
        } catch {
            MagicMessageProvider.shared.error("创建目标目录失败：\(error)")
            return
        }
        
        // 生成不同尺寸的PNG文件
        let sizes = [16, 32, 48, 64, 128, 256, 512, 1024]
        for size in sizes {
            await generatePNG(size: size, folderPath: folderPath, tag: tag, iconAsset: iconAsset)
        }
        
        MagicMessageProvider.shared.info("PNG格式下载完成，保存在：\(folderPath.path)")
    }
    
    @MainActor private func downloadFavicon() async {
        guard let iconAsset = currentIconAsset else {
            MagicMessageProvider.shared.error("没有可用的图标资源")
            return
        }
        
        isGenerating = true
        defer { isGenerating = false }
        
        let tag = Date.nowCompact
        let folderName = "Favicon-\(tag)"
        
        guard let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
            MagicMessageProvider.shared.error("无权访问下载文件夹")
            return
        }
        
        let folderPath = downloadsURL.appendingPathComponent(folderName, isDirectory: true)
        
        do {
            try FileManager.default.createDirectory(at: folderPath, withIntermediateDirectories: true)
        } catch {
            MagicMessageProvider.shared.error("创建目标目录失败：\(error)")
            return
        }
        
        // 生成不同尺寸的PNG文件
        let sizes = [16, 32, 48]
        for size in sizes {
            await generatePNG(size: size, folderPath: folderPath, tag: tag, iconAsset: iconAsset)
        }
        
        MagicMessageProvider.shared.info("Favicon下载完成，保存在：\(folderPath.path)")
    }
    
    // MARK: - 生成方法
    
    @MainActor private func generatePNG(size: Int, folderPath: URL, tag: String, iconAsset: IconAsset) async {
        let fileName = "\(tag)-\(size)x\(size).png"
        let saveTo = folderPath.appendingPathComponent(fileName)
        
        _ = MagicImage.snapshot(
            MagicImage.makeImage(
                IconRenderer.renderIcon(iconData: icon, iconAsset: iconAsset)
                    .frame(width: CGFloat(size), height: CGFloat(size))
            )
            .resizable()
            .scaledToFit()
            .frame(width: CGFloat(size), height: CGFloat(size)),
            path: saveTo
        )
    }
    
    @MainActor private func generateAllPNG(folderPath: URL, tag: String, iconAsset: IconAsset) async {
        let sizes = [16, 32, 48, 64, 128, 256, 512, 1024]
        for size in sizes {
            await generatePNG(size: size, folderPath: folderPath, tag: tag, iconAsset: iconAsset)
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
    .frame(height: 800)
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
