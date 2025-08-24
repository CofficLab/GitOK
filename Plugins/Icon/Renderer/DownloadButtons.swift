import MagicCore
import SwiftUI
import UniformTypeIdentifiers

/**
 * 图标下载按钮组件
 * 提供多种格式的图标下载功能
 * 支持PNG、Favicon、Xcode等格式
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
                // Xcode格式下载
                Button("下载 Xcode 格式") {
                    Task {
                        await downloadXcode()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isGenerating || currentIconAsset == nil)
                
                // PNG格式下载
                Button("下载 PNG 格式") {
                    Task {
                        await downloadPNG()
                    }
                }
                .buttonStyle(.bordered)
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
            
            if isGenerating {
                ProgressView("正在生成...")
                    .progressViewStyle(.circular)
            }
            
            if currentIconAsset == nil {
                Text("请先选择一个图标")
                    .font(.caption)
                    .foregroundColor(.secondary)
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
    
    @MainActor private func downloadXcode() async {
        guard let iconAsset = currentIconAsset else {
            MagicMessageProvider.shared.error("没有可用的图标资源")
            return
        }
        
        isGenerating = true
        defer { isGenerating = false }
        
        let tag = Date.nowCompact
        let folderName = "XcodeIcons-\(tag).appiconset"
        
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
        
        // 生成macOS图标
        await generateMacOSIcons(folderPath: folderPath, tag: tag, iconAsset: iconAsset)
        
        // 生成iOS图标
        await generateIOSIcons(folderPath: folderPath, tag: tag, iconAsset: iconAsset)
        
        // 生成Contents.json文件
        await generateContentJson(folderPath: folderPath, tag: tag)
        
        // 生成README文件
        await generateReadmeFile(folderPath: folderPath, tag: tag)
        
        MagicMessageProvider.shared.success("Xcode图标集生成完成！\n保存位置：\(folderPath.path)\n\n使用方法：\n1. 将整个 .appiconset 文件夹复制到你的 Xcode 项目中\n2. 在 Assets.xcassets 中右键选择 'New App Icon Set'\n3. 将生成的图标文件拖拽到对应的尺寸位置")
    }
    
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
        
        MagicMessageProvider.shared.info("开始生成PNG格式图标...")
        
        // 生成不同尺寸的PNG文件
        let sizes = [16, 32, 48, 64, 128, 256, 512, 1024]
        var successCount = 0
        
        for (index, size) in sizes.enumerated() {
            MagicMessageProvider.shared.info("生成 \(size)x\(size) 图标... (\(index + 1)/\(sizes.count))")
            
            if await generatePNG(size: size, folderPath: folderPath, tag: tag, iconAsset: iconAsset) {
                successCount += 1
            }
        }
        
        if successCount == sizes.count {
            MagicMessageProvider.shared.success("PNG格式下载完成！\n保存位置：\(folderPath.path)\n成功生成 \(successCount) 个图标文件")
        } else {
            MagicMessageProvider.shared.warning("PNG格式生成完成，但有部分失败\n保存位置：\(folderPath.path)\n成功：\(successCount)/\(sizes.count)")
        }
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
        
        MagicMessageProvider.shared.info("开始生成Favicon图标...")
        
        // 生成不同尺寸的PNG文件
        let sizes = [16, 32, 48]
        var successCount = 0
        
        for (index, size) in sizes.enumerated() {
            MagicMessageProvider.shared.info("生成 favicon \(size)x\(size) 图标... (\(index + 1)/\(sizes.count))")
            
            if await generatePNG(size: size, folderPath: folderPath, tag: tag, iconAsset: iconAsset) {
                successCount += 1
            }
        }
        
        // 生成HTML引用代码
        await generateFaviconHTML(folderPath: folderPath)
        
        if successCount == sizes.count {
            MagicMessageProvider.shared.success("Favicon下载完成！\n保存位置：\(folderPath.path)\n成功生成 \(successCount) 个图标文件 + HTML引用代码")
        } else {
            MagicMessageProvider.shared.warning("Favicon生成完成，但有部分失败\n保存位置：\(folderPath.path)\n成功：\(successCount)/\(sizes.count)")
        }
    }
    
    // MARK: - 生成方法
    
    @MainActor private func generateMacOSIcons(folderPath: URL, tag: String, iconAsset: IconAsset) async {
        let sizes = [16, 32, 128, 256, 512]
        
        for (index, size) in sizes.enumerated() {
            let fileName = "\(tag)-macOS-\(size)x\(size).png"
            let saveTo = folderPath.appendingPathComponent(fileName)
            
            // 显示生成进度
            MagicMessageProvider.shared.info("生成 macOS \(size)x\(size) 图标...")
            
            let _ = MagicImage.snapshot(
                MagicImage.makeImage(
                    IconRenderer.renderIcon(iconData: icon, iconAsset: iconAsset)
                        .frame(width: CGFloat(size), height: CGFloat(size))
                )
                .resizable()
                .scaledToFit()
                .frame(width: CGFloat(size), height: CGFloat(size)),
                path: saveTo
            )
            
            // 检查文件是否生成成功
            if FileManager.default.fileExists(atPath: saveTo.path) {
                MagicMessageProvider.shared.info("✅ 成功生成 \(fileName)")
            } else {
                MagicMessageProvider.shared.error("❌ 生成 \(fileName) 失败")
            }
        }
    }
    
    @MainActor private func generateIOSIcons(folderPath: URL, tag: String, iconAsset: IconAsset) async {
        let size = 1024
        let fileName = "\(tag)-iOS-\(size)x\(size).png"
        let saveTo = folderPath.appendingPathComponent(fileName)
        
        MagicMessageProvider.shared.info("生成 iOS \(size)x\(size) 图标...")
        
        let _ = MagicImage.snapshot(
            MagicImage.makeImage(
                IconRenderer.renderIcon(iconData: icon, iconAsset: iconAsset)
                    .frame(width: CGFloat(size), height: CGFloat(size))
            )
            .resizable()
            .scaledToFit()
            .frame(width: CGFloat(size), height: CGFloat(size)),
            path: saveTo
        )
        
        // 检查文件是否生成成功
        if FileManager.default.fileExists(atPath: saveTo.path) {
            MagicMessageProvider.shared.info("✅ 成功生成 \(fileName)")
        } else {
            MagicMessageProvider.shared.error("❌ 生成 \(fileName) 失败")
        }
    }
    
    @MainActor private func generateContentJson(folderPath: URL, tag: String) async {
        let imageSet: [[String: Any]] = [
            ["filename": "\(tag)-macOS-16x16.png", "idiom": "mac", "scale": "1x", "size": "16x16"],
            ["filename": "\(tag)-macOS-32x32.png", "idiom": "mac", "scale": "1x", "size": "32x32"],
            ["filename": "\(tag)-macOS-128x128.png", "idiom": "mac", "scale": "1x", "size": "128x128"],
            ["filename": "\(tag)-macOS-256x256.png", "idiom": "mac", "scale": "1x", "size": "256x256"],
            ["filename": "\(tag)-macOS-512x512.png", "idiom": "mac", "scale": "1x", "size": "512x512"],
            ["filename": "\(tag)-iOS-1024x1024.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"]
        ]
        
        let jsonData = try! JSONSerialization.data(
            withJSONObject: [
                "images": imageSet,
                "info": [
                    "author": "xcode",
                    "version": 1,
                ],
            ],
            options: [.prettyPrinted]
        )
        
        do {
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                try jsonString.write(
                    to: folderPath.appendingPathComponent("Contents.json"),
                    atomically: true,
                    encoding: .utf8
                )
                MagicMessageProvider.shared.info("生成 Contents.json 配置文件")
            }
        } catch {
            MagicMessageProvider.shared.error("生成 Contents.json 失败：\(error)")
        }
    }
    
    @MainActor private func generateReadmeFile(folderPath: URL, tag: String) async {
        let fileName = "README.md"
        let saveTo = folderPath.appendingPathComponent(fileName)
        
        let readmeContent = """
        # Xcode 图标集使用说明
        
        ## 文件说明
        
        这个 `.appiconset` 文件夹包含了适用于 iOS 和 macOS 应用的所有图标文件。
        
        ## 使用方法
        
        ### 方法1：直接导入（推荐）
        1. 将整个图标集文件夹复制到你的 Xcode 项目中
        2. 在 `Assets.xcassets` 中右键选择 "New App Icon Set"
        3. 将生成的图标文件拖拽到对应的尺寸位置
        
        ### 方法2：手动配置
        1. 在 Xcode 中创建新的 App Icon Set
        2. 将对应的图标文件拖拽到正确的尺寸位置
        
        ## 图标尺寸说明
        
        ### macOS 图标
        - 16×16: 菜单栏、Dock 小图标
        - 32×32: 菜单栏、Dock 图标
        - 128×128: Finder 图标
        - 256×256: Finder 大图标
        - 512×512: 高分辨率显示器
        
        ### iOS 图标
        - 1024×1024: App Store 图标
        
        ## 注意事项
        
        - 所有图标都使用 PNG 格式，支持透明背景
        - 图标已根据设计规范优化，确保在不同尺寸下都清晰显示
        - 如果需要在 Xcode 中调整图标，建议使用矢量工具重新生成
        
        ## 生成信息
        
        - 生成时间：\(Date().formatted())
        - 图标标题：\(icon.title)
        - 背景样式：\(icon.backgroundId)
        - 圆角设置：\(icon.cornerRadius)
        - 缩放比例：\(icon.scale ?? 1.0)
        - 透明度：\(icon.opacity)
        
        ---
        由 GitOK 图标生成器创建
        """
        
        do {
            try readmeContent.write(to: saveTo, atomically: true, encoding: .utf8)
            MagicMessageProvider.shared.info("生成 README.md 说明文件")
        } catch {
            MagicMessageProvider.shared.error("生成 README.md 失败：\(error)")
        }
    }
    
    @MainActor private func generatePNG(size: Int, folderPath: URL, tag: String, iconAsset: IconAsset) async -> Bool {
        let fileName = "\(tag)-\(size)x\(size).png"
        let saveTo = folderPath.appendingPathComponent(fileName)
        
        let _ = MagicImage.snapshot(
            MagicImage.makeImage(
                IconRenderer.renderIcon(iconData: icon, iconAsset: iconAsset)
                    .frame(width: CGFloat(size), height: CGFloat(size))
            )
            .resizable()
            .scaledToFit()
            .frame(width: CGFloat(size), height: CGFloat(size)),
            path: saveTo
        )
        
        // 返回文件是否成功生成
        return FileManager.default.fileExists(atPath: saveTo.path)
    }
    
    @MainActor private func generateFaviconHTML(folderPath: URL) async {
        let fileName = "favicon-html.html"
        let saveTo = folderPath.appendingPathComponent(fileName)
        
        let htmlCode = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Favicon 引用代码</title>
            <meta charset="utf-8">
        </head>
        <body>
            <h1>Favicon 引用代码</h1>
            <p>将以下代码添加到你的HTML文件的 &lt;head&gt; 部分：</p>

            <h2>PNG格式（推荐）</h2>
            <pre><code>&lt;link rel="icon" type="image/png" sizes="16x16" href="/favicon-16x16.png"&gt;
        &lt;link rel="icon" type="image/png" sizes="32x32" href="/favicon-32x32.png"&gt;
        &lt;link rel="icon" type="image/png" sizes="48x48" href="/favicon-48x48.png"&gt;</code></pre>

            <h2>Apple Touch Icon</h2>
            <pre><code>&lt;link rel="apple-touch-icon" sizes="180x180" href="/apple-touch-icon.png"&gt;</code></pre>
            
            <h2>Windows 磁贴</h2>
            <pre><code>&lt;meta name="msapplication-TileColor" content="#ffffff"&gt;
        &lt;meta name="msapplication-TileImage" content="/mstile-144x144.png"&gt;</code></pre>
            
            <hr>
            <p><small>由 GitOK 图标生成器创建 - \(Date().formatted())</small></p>
        </body>
        </html>
        """
        
        do {
            try htmlCode.write(to: saveTo, atomically: true, encoding: .utf8)
            MagicMessageProvider.shared.info("生成 HTML 引用代码文件")
        } catch {
            MagicMessageProvider.shared.error("生成 HTML 文件失败：\(error)")
        }
    }
    
    @MainActor private func generateAllPNG(folderPath: URL, tag: String, iconAsset: IconAsset) async {
        let sizes = [16, 32, 48, 64, 128, 256, 512, 1024]
        for size in sizes {
            _ = await generatePNG(size: size, folderPath: folderPath, tag: tag, iconAsset: iconAsset)
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
