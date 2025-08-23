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
                    subtitle: "iOS & macOS 应用图标",
                    icon: "app.badge",
                    color: .blue
                ) {
                    downloadXcodeFormat()
                }
                
                // Favicon 格式下载
                DownloadButton(
                    title: "下载 Favicon 格式",
                    subtitle: "网站图标 (16×16, 32×32, 48×48)",
                    icon: "globe",
                    color: .green
                ) {
                    downloadFaviconFormat()
                }
                
                // 通用 PNG 格式下载
                DownloadButton(
                    title: "下载 PNG 格式",
                    subtitle: "高分辨率图标文件",
                    icon: "photo",
                    color: .orange
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
        await generateContentJson(folderPath: folderPath)
        
        MagicMessageProvider.shared.success("Xcode图标已生成到：\(folderPath.path)")
    }
    
    @MainActor private func generateMacOSIcons(folderPath: URL, tag: String) async {
        let sizes = [16, 32, 64, 128, 256, 512, 1024]
        
        for size in sizes {
            let fileName = "\(tag)-macOS-\(size)x\(size).png"
            let saveTo = folderPath.appendingPathComponent(fileName)
            
            _ = MagicImage.snapshot(
                MagicImage.makeImage(
                    ZStack {
                        icon.background
                            .frame(width: CGFloat(size), height: CGFloat(size))
                            .cornerRadius(CGFloat(size) * 0.2)
                        
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
                        .cornerRadius(CGFloat(size) * 0.2)
                    
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
    
    @MainActor private func generateContentJson(folderPath: URL) async {
        let imageSet: [[String: Any]] = [
            ["filename": "icon-16x16.png", "idiom": "mac", "scale": "1x", "size": "16x16"],
            ["filename": "icon-32x32.png", "idiom": "mac", "scale": "1x", "size": "32x32"],
            ["filename": "icon-64x64.png", "idiom": "mac", "scale": "1x", "size": "64x64"],
            ["filename": "icon-128x128.png", "idiom": "mac", "scale": "1x", "size": "128x128"],
            ["filename": "icon-256x256.png", "idiom": "mac", "scale": "1x", "size": "256x256"],
            ["filename": "icon-512x512.png", "idiom": "mac", "scale": "1x", "size": "512x512"],
            ["filename": "icon-1024x1024.png", "idiom": "mac", "scale": "1x", "size": "1024x1024"],
            ["filename": "icon-1024x1024.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"]
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
                        .cornerRadius(CGFloat(size) * 0.2)
                    
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
                        .cornerRadius(CGFloat(size) * 0.2)
                    
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

/**
 * 单个下载按钮组件
 */
struct DownloadButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.down.circle")
                    .font(.title3)
                    .foregroundColor(color)
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
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
