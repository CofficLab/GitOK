import MagicCore
import SwiftUI

/**
 * 图标下载按钮区域
 * 提供多种格式的图标下载选项
 * 包括Xcode格式、Favicon格式等
 */
struct DownloadButtons: View {
    let icon: IconModel
    @State private var isGenerating = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("下载图标")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                // Xcode 格式下载
                DownloadButton(
                    title: "下载 Xcode 格式",
                    icon: "app.badge",
                    color: .blue,
                    infoText: "生成适用于 iOS 和 macOS 应用的图标集，包含 Contents.json 文件，可直接导入到 Xcode 项目中。支持多种尺寸：16×16、32×32、64×64、128×128、256×256、512×512、1024×1024。"
                ) {
                    downloadXcodeFormat()
                }
                
                // Favicon 格式下载
                DownloadButton(
                    title: "下载 Favicon 格式",
                    icon: "globe",
                    color: .green,
                    infoText: "生成网站图标文件，包含三种常用尺寸：16×16、32×32、48×48。还会生成 HTML 引用代码文件，方便集成到网站中。适用于网页标签栏、书签等场景。"
                ) {
                    downloadFaviconFormat()
                }
                
                // 通用 PNG 格式下载
                DownloadButton(
                    title: "下载 PNG 格式",
                    icon: "photo",
                    color: .orange,
                    infoText: "生成高分辨率 PNG 图标文件，包含多种尺寸：16×16、32×32、64×64、128×128、256×256、512×512、1024×1024。支持自定义圆角设置，适用于各种设计场景。"
                ) {
                    downloadPNGFormat()
                }
                

            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func downloadXcodeFormat() {
        isGenerating = true
        
        Task {
            await generateXcodeIcons()
            await MainActor.run {
                isGenerating = false
            }
        }
    }
    
    private func downloadFaviconFormat() {
        isGenerating = true
        
        Task {
            await generateFavicon()
            await MainActor.run {
                isGenerating = false
            }
        }
    }
    
    private func downloadPNGFormat() {
        isGenerating = true
        
        Task {
            await generatePNGIcons()
            await MainActor.run {
                isGenerating = false
            }
        }
    }
    
    @MainActor private func generateXcodeIcons() async {
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
        await generateMacOSIcons(folderPath: folderPath, tag: tag)
        
        // 生成iOS图标
        await generateIOSIcons(folderPath: folderPath, tag: tag)
        
        // 生成Contents.json文件
        await generateContentJson(folderPath: folderPath, tag: tag)
        
        MagicMessageProvider.shared.success("Xcode图标已生成到：\(folderPath.path)")
    }
    
    @MainActor private func generateMacOSIcons(folderPath: URL, tag: String) async {
        let sizes = [16, 32, 128, 256, 512]
        
        for size in sizes {
            let fileName = "\(tag)-macOS-\(size)x\(size).png"
            let saveTo = folderPath.appendingPathComponent(fileName)
            
            _ = MagicImage.snapshot(
                MagicImage.makeImage(
                    ZStack {
                        icon.background
                            .frame(width: CGFloat(size), height: CGFloat(size))
                            .cornerRadius(icon.cornerRadius > 0 ? CGFloat(icon.cornerRadius) : 0)
                        
                        icon.image
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(icon.scale ?? 1.0)
                            .frame(width: CGFloat(size) * 0.8, height: CGFloat(size) * 0.8)
                    }
                )
                .resizable()
                .scaledToFit()
                .frame(width: CGFloat(size), height: CGFloat(size)),
                path: saveTo
            )
        }
    }
    
    @MainActor private func generateIOSIcons(folderPath: URL, tag: String) async {
        let size = 1024
        let fileName = "\(tag)-iOS-\(size)x\(size).png"
        let saveTo = folderPath.appendingPathComponent(fileName)
        
                    _ = MagicImage.snapshot(
                MagicImage.makeImage(
                    ZStack {
                        icon.background
                            .frame(width: CGFloat(size), height: CGFloat(size))
                            .cornerRadius(icon.cornerRadius > 0 ? CGFloat(icon.cornerRadius) : 0)
                        
                        icon.image
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(icon.scale ?? 1.0)
                            .frame(width: CGFloat(size) * 0.8, height: CGFloat(size) * 0.8)
                    }
                )
                .resizable()
                .scaledToFit()
                .frame(width: CGFloat(size), height: CGFloat(size)),
                path: saveTo
            )
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
        
        try! String(data: jsonData, encoding: .utf8)!.write(
            to: folderPath.appendingPathComponent("Contents.json"),
            atomically: true,
            encoding: .utf8
        )
    }
    
    @MainActor private func generateFavicon() async {
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
            let fileName = "favicon-\(size)x\(size).png"
            let saveTo = folderPath.appendingPathComponent(fileName)
            
            _ = MagicImage.snapshot(
                ZStack {
                    icon.background
                        .frame(width: CGFloat(size), height: CGFloat(size))
                        .cornerRadius(icon.cornerRadius > 0 ? CGFloat(icon.cornerRadius) : 0)
                    
                    icon.image
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(icon.scale ?? 1.0)
                        .frame(width: CGFloat(size) * 0.8, height: CGFloat(size) * 0.8)
                }
                .frame(width: CGFloat(size), height: CGFloat(size)),
                path: saveTo
            )
        }
        
        // 生成HTML引用代码
        await generateHTMLCode(folderPath: folderPath)
        
        MagicMessageProvider.shared.success("Favicon 已生成到：\(folderPath.path)")
    }
    
    @MainActor private func generateHTMLCode(folderPath: URL) async {
        let fileName = "favicon-html.html"
        let saveTo = folderPath.appendingPathComponent(fileName)
        
        let htmlCode = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Favicon 引用代码</title>
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
        </body>
        </html>
        """
        
        try? htmlCode.write(to: saveTo, atomically: true, encoding: .utf8)
    }
    
    @MainActor private func generatePNGIcons() async {
        let tag = Date.nowCompact
        let folderName = "PNGIcons-\(tag)"
        
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
        let sizes = [16, 32, 64, 128, 256, 512, 1024]
        for size in sizes {
            let fileName = "icon-\(size)x\(size).png"
            let saveTo = folderPath.appendingPathComponent(fileName)
            
            _ = MagicImage.snapshot(
                ZStack {
                    icon.background
                        .frame(width: CGFloat(size), height: CGFloat(size))
                        .cornerRadius(icon.cornerRadius > 0 ? CGFloat(icon.cornerRadius) : 0)
                    
                    icon.image
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(icon.scale ?? 1.0)
                        .frame(width: CGFloat(size) * 0.8, height: CGFloat(size) * 0.8)
                }
                .frame(width: CGFloat(size), height: CGFloat(size)),
                path: saveTo
            )
        }
        
        MagicMessageProvider.shared.success("PNG图标已生成到：\(folderPath.path)")
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
