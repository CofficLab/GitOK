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
    @State private var isGenerating = false
    
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
                .disabled(isGenerating)
                
                // SVG格式下载
                Button("下载 SVG 格式") {
                    Task {
                        await downloadSVG()
                    }
                }
                .buttonStyle(.bordered)
                .disabled(isGenerating)
                
                // Favicon下载
                Button("下载 Favicon") {
                    Task {
                        await downloadFavicon()
                    }
                }
                .buttonStyle(.bordered)
                .disabled(isGenerating)
                
                // 批量下载
                Button("批量下载所有格式") {
                    Task {
                        await downloadAll()
                    }
                }
                .buttonStyle(.bordered)
                .disabled(isGenerating)
            }
            
            if isGenerating {
                ProgressView("正在生成...")
                    .progressViewStyle(.circular)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - 下载方法
    
    @MainActor private func downloadPNG() async {
        isGenerating = true
        defer { isGenerating = false }
        
        let tag = Date().nowCompact
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
            await generatePNG(size: size, folderPath: folderPath, tag: tag)
        }
        
        MagicMessageProvider.shared.info("PNG格式下载完成，保存在：\(folderPath.path)")
    }
    
    @MainActor private func downloadSVG() async {
        isGenerating = true
        defer { isGenerating = false }
        
        let tag = Date().nowCompact
        let folderName = "SVG-\(tag)"
        
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
        
        // 生成SVG文件
        await generateSVG(folderPath: folderPath, tag: tag)
        
        MagicMessageProvider.shared.info("SVG格式下载完成，保存在：\(folderPath.path)")
    }
    
    @MainActor private func downloadFavicon() async {
        isGenerating = true
        defer { isGenerating = false }
        
        let tag = Date().nowCompact
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
            await generatePNG(size: size, folderPath: folderPath, tag: tag)
        }
        
        // 生成ICO文件
        await generateICO(folderPath: folderPath, tag: tag)
        
        MagicMessageProvider.shared.info("Favicon下载完成，保存在：\(folderPath.path)")
    }
    
    @MainActor private func downloadAll() async {
        isGenerating = true
        defer { isGenerating = false }
        
        let tag = Date().nowCompact
        let folderName = "All-Formats-\(tag)"
        
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
        
        // 创建子文件夹
        let pngFolder = folderPath.appendingPathComponent("PNG", isDirectory: true)
        let svgFolder = folderPath.appendingPathComponent("SVG", isDirectory: true)
        let faviconFolder = folderPath.appendingPathComponent("Favicon", isDirectory: true)
        
        try! FileManager.default.createDirectory(at: pngFolder, withIntermediateDirectories: true)
        try! FileManager.default.createDirectory(at: svgFolder, withIntermediateDirectories: true)
        try! FileManager.default.createDirectory(at: faviconFolder, withIntermediateDirectories: true)
        
        // 并行生成所有格式
        async let pngTask = generateAllPNG(folderPath: pngFolder, tag: tag)
        async let svgTask = generateSVG(folderPath: svgFolder, tag: tag)
        async let faviconTask = generateAllFavicon(folderPath: faviconFolder, tag: tag)
        
        await (pngTask, svgTask, faviconTask)
        
        MagicMessageProvider.shared.info("所有格式下载完成，保存在：\(folderPath.path)")
    }
    
    // MARK: - 生成方法
    
    @MainActor private func generatePNG(size: Int, folderPath: URL, tag: String) async {
        let fileName = "\(tag)-\(size)x\(size).png"
        let saveTo = folderPath.appendingPathComponent(fileName)
        
        // 创建临时IconAsset用于渲染
        let tempIconAsset = IconAsset(fileURL: URL(fileURLWithPath: "/tmp/default.png"))
        
        _ = MagicImage.snapshot(
            MagicImage.makeImage(
                IconRenderer.renderIcon(iconData: icon, iconAsset: tempIconAsset)
                    .frame(width: CGFloat(size), height: CGFloat(size))
            )
            .resizable()
            .scaledToFit()
            .frame(width: CGFloat(size), height: CGFloat(size)),
            path: saveTo
        )
    }
    
    @MainActor private func generateAllPNG(folderPath: URL, tag: String) async {
        let sizes = [16, 32, 48, 64, 128, 256, 512, 1024]
        for size in sizes {
            await generatePNG(size: size, folderPath: folderPath, tag: tag)
        }
    }
    
    @MainActor private func generateSVG(folderPath: URL, tag: String) async {
        let fileName = "\(tag).svg"
        let saveTo = folderPath.appendingPathComponent(fileName)
        
        // 创建临时IconAsset用于渲染
        let tempIconAsset = IconAsset(fileURL: URL(fileURLWithPath: "/tmp/default.png"))
        
        // 生成SVG内容
        let svgContent = generateSVGContent(iconData: icon, iconAsset: tempIconAsset)
        
        try! svgContent.write(to: saveTo, atomically: true, encoding: .utf8)
    }
    
    @MainActor private func generateICO(folderPath: URL, tag: String) async {
        let fileName = "\(tag).ico"
        let saveTo = folderPath.appendingPathComponent(fileName)
        
        // 创建临时IconAsset用于渲染
        let tempIconAsset = IconAsset(fileURL: URL(fileURLWithPath: "/tmp/default.png"))
        
        // 生成ICO文件（这里简化处理，实际应该生成真正的ICO格式）
        let icoContent = generateICOContent(iconData: icon, iconAsset: tempIconAsset)
        
        try! icoContent.write(to: saveTo, atomically: true, encoding: .utf8)
    }
    
    @MainActor private func generateAllFavicon(folderPath: URL, tag: String) async {
        let sizes = [16, 32, 48]
        for size in sizes {
            await generatePNG(size: size, folderPath: folderPath, tag: tag)
        }
        await generateICO(folderPath: folderPath, tag: tag)
    }
    
    // MARK: - 辅助方法
    
    private func generateSVGContent(iconData: IconData, iconAsset: IconAsset) -> String {
        // 简化的SVG生成，实际应该根据IconRenderer的结果生成
        return """
        <svg width="512" height="512" xmlns="http://www.w3.org/2000/svg">
            <rect width="512" height="512" fill="url(#background)" rx="\(iconData.cornerRadius)"/>
            <image href="data:image/png;base64,..." width="\(512 * (iconData.scale ?? 1.0))" height="\(512 * (iconData.scale ?? 1.0))" x="\(256 - (512 * (iconData.scale ?? 1.0)) / 2)" y="\(256 - (512 * (iconData.scale ?? 1.0)) / 2)"/>
        </svg>
        """
    }
    
    private func generateICOContent(iconData: IconData, iconAsset: IconAsset) -> String {
        // 简化的ICO生成，实际应该生成真正的ICO格式
        return "ICO file content for \(iconData.title)"
    }
}

// MARK: - 日期扩展

extension Date {
    var nowCompact: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: self)
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
