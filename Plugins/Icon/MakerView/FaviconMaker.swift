import SwiftUI
import MagicCore

/**
 * Favicon生成器组件
 * 负责生成网站favicon，支持多种尺寸和格式
 */
struct FaviconMaker: View {
    let icon: IconModel
    @State private var imageSet: [Any] = []
    @State private var folderPath: URL? = nil
    
    private let tag = Date.nowCompact
    private var folderName: String { "Favicon-\(tag)" }
    
    var body: some View {
        VStack(spacing: 20) {
            
            // 预览区域
            VStack(spacing: 16) {
                HStack(spacing: 20) {
                    // 16x16 预览
                    VStack {
                        Text("16×16")
                            .font(.caption)
                        IconPreview(icon: icon, platform: "favicon")
                            .frame(width: 16, height: 16)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(2)
                    }
                    
                    // 32x32 预览
                    VStack {
                        Text("32×32")
                            .font(.caption)
                        IconPreview(icon: icon, platform: "favicon")
                            .frame(width: 32, height: 32)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(4)
                    }
                    
                    // 48x48 预览
                    VStack {
                        Text("48×48")
                            .font(.caption)
                        IconPreview(icon: icon, platform: "favicon")
                            .frame(width: 48, height: 48)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(6)
                    }
                    
                    Button("下载") {
                        generateFavicon()
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .padding()
    }
    
    @MainActor private func generateFavicon() {
        imageSet = []
        
        let (message, path) = getFolderPath()
        if path == nil {MagicMessageProvider.shared.error("错误：\(message)")
            return
        }
        
        folderPath = path
        
        // 生成不同尺寸的PNG文件
        generatePNGFiles()
        
        // 生成SVG文件
        generateSVGFile()
        
        // 生成HTML引用代码
        generateHTMLCode()
        
        MagicMessageProvider.shared.success("Favicon 已生成到：\(folderPath?.path ?? "")")
    }
    
    @MainActor private func generatePNGFiles() {
        guard let folderPath = folderPath else { return }
        
        let sizes = [16, 32, 48]
        
        for size in sizes {
            let fileName = "favicon-\(size)x\(size).png"
            let saveTo = folderPath.appendingPathComponent(fileName)
            
            _ = MagicImage.snapshot(
                IconPreview(icon: icon, platform: "favicon")
                    .frame(width: CGFloat(size), height: CGFloat(size)),
                path: saveTo
            )
            
            imageSet.append([
                "filename": fileName,
                "size": "\(size)x\(size)",
                "type": "png"
            ])
        }
    }
    

    
    @MainActor private func generateSVGFile() {
        guard let folderPath = folderPath else { return }
        
        let fileName = "favicon.svg"
        let saveTo = folderPath.appendingPathComponent(fileName)
        
        // 生成SVG文件（矢量格式）
        let svgContent = """
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
            <rect width="32" height="32" fill="#ffffff"/>
            <text x="16" y="20" text-anchor="middle" font-family="Arial" font-size="16" fill="#000000">F</text>
        </svg>
        """
        
        try? svgContent.write(to: saveTo, atomically: true, encoding: .utf8)
        
        imageSet.append([
            "filename": fileName,
            "type": "svg",
            "note": "示例SVG文件"
        ])
    }
    
    @MainActor private func generateHTMLCode() {
        guard let folderPath = folderPath else { return }
        
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
            
            <h2>SVG格式（现代浏览器）</h2>
            <pre><code>&lt;link rel="icon" type="image/svg+xml" href="/favicon.svg"&gt;</code></pre>
            
            <h2>Apple Touch Icon</h2>
            <pre><code>&lt;link rel="apple-touch-icon" sizes="180x180" href="/apple-touch-icon.png"&gt;</code></pre>
        </body>
        </html>
        """
        
        try? htmlCode.write(to: saveTo, atomically: true, encoding: .utf8)
        
        imageSet.append([
            "filename": fileName,
            "type": "html",
            "note": "HTML引用代码"
        ])
    }
    
    private func getFolderPath() -> (message: String, path: URL?) {
        guard let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
            return ("无权访问下载文件夹", nil)
        }
        
        let folderPath = downloadsURL.appendingPathComponent(folderName, isDirectory: true)
        
        if !FileManager.default.fileExists(atPath: folderPath.path) {
            do {
                try FileManager.default.createDirectory(
                    at: folderPath,
                    withIntermediateDirectories: true
                )
            } catch {
                return ("创建目标目录失败：\(error)", nil)
            }
        }
        
        return ("成功", folderPath)
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
