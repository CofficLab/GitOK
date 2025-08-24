import MagicCore
import SwiftUI

/**
 * Favicon 下载按钮
 * 专门处理 Favicon 图标的下载和生成
 * 支持多种尺寸的 Favicon 图标和 HTML 引用代码
 */
struct FaviconDownloadButton: View {
    let iconProvider: IconProvider
    let currentIconAsset: IconAsset?
    
    @State private var isGenerating = false
    @State private var progressText = ""

    var body: some View {
        DownloadButton(
            title: progressText.isEmpty ? "下载 Favicon" : progressText,
            icon: "globe",
            color: .orange,
            action: {
                Task {
                    await downloadFavicon()
                }
            },
            isDisabled: isGenerating || currentIconAsset == nil || iconProvider.currentData == nil
        )
    }

    @MainActor private func downloadFavicon() async {
        guard let iconAsset = currentIconAsset else {
            MagicMessageProvider.shared.error("没有可用的图标资源")
            return
        }

        isGenerating = true
        progressText = "正在生成 Favicon..."
        defer { 
            isGenerating = false
            progressText = ""
        }

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
        var successCount = 0

        for (index, size) in sizes.enumerated() {
            progressText = "正在生成 Favicon \(size)×\(size) (\(index + 1)/\(sizes.count))"
            if await generatePNG(size: size, folderPath: folderPath, tag: tag, iconAsset: iconAsset) {
                successCount += 1
            }
        }

        // 生成HTML引用代码
        progressText = "正在生成 HTML 引用代码..."
        await generateFaviconHTML(folderPath: folderPath)

        if successCount == sizes.count {
            MagicMessageProvider.shared.success("Favicon图标集已保存到下载目录")
        } else {
            MagicMessageProvider.shared.warning("Favicon生成完成，但有部分失败\n保存位置：\(folderPath.path)\n成功：\(successCount)/\(sizes.count)")
        }
    }

    @MainActor private func generatePNG(size: Int, folderPath: URL, tag: String, iconAsset: IconAsset) async -> Bool {
        guard let iconData = iconProvider.currentData else {
            MagicMessageProvider.shared.error("没有可用的图标数据")
            return false
        }

        let fileName = "\(tag)-\(size)x\(size).png"
        let saveTo = folderPath.appendingPathComponent(fileName)

        let success = await IconRenderer.snapshotIcon(iconData: iconData, iconAsset: iconAsset, size: size, savePath: saveTo)

        // 返回文件是否成功生成
        return success
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
