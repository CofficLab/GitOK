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

        // 生成ICO文件
        progressText = "正在生成 ICO 文件..."
        if await generateICO(folderPath: folderPath, tag: tag, iconAsset: iconAsset) {
            successCount += 1
        }

        // 生成HTML引用代码
        progressText = "正在生成 HTML 引用代码..."
        await generateFaviconHTML(folderPath: folderPath)

        if successCount == sizes.count + 1 { // PNG文件 + ICO文件
            MagicMessageProvider.shared.success("Favicon图标集已保存到下载目录")
        } else {
            MagicMessageProvider.shared.warning("Favicon生成完成，但有部分失败\n保存位置：\(folderPath.path)\n成功：\(successCount)/\(sizes.count + 1)")
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

            <h2>ICO格式（主要favicon）</h2>
            <pre><code>&lt;link rel="icon" type="image/x-icon" href="/favicon.ico"&gt;</code></pre>

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

    @MainActor private func generateICO(folderPath: URL, tag: String, iconAsset: IconAsset) async -> Bool {
        guard let iconData = iconProvider.currentData else {
            MagicMessageProvider.shared.error("没有可用的图标数据")
            return false
        }

        let fileName = "\(tag)-favicon.ico"
        let saveTo = folderPath.appendingPathComponent(fileName)

        // 生成32x32的PNG作为ICO的基础（最常用的尺寸）
        let tempPNGPath = folderPath.appendingPathComponent("\(tag)-temp-32x32.png")

        let success = await IconRenderer.snapshotIcon(iconData: iconData, iconAsset: iconAsset, size: 32, savePath: tempPNGPath)

        if !success {
            MagicMessageProvider.shared.error("生成ICO临时文件失败")
            return false
        }

        // 将PNG转换为ICO格式
        do {
            // 读取临时PNG文件
            guard let pngData = try? Data(contentsOf: tempPNGPath) else {
                MagicMessageProvider.shared.error("读取临时PNG文件失败")
                return false
            }

            // 创建ICO文件头和目录
            var icoData = Data()

            // ICO文件头 (6字节)
            // 保留字段 (2字节): 0
            icoData.append(contentsOf: [0x00, 0x00])
            // 类型 (2字节): 1表示ICO
            icoData.append(contentsOf: [0x01, 0x00])
            // 图像数量 (2字节): 1个图像
            icoData.append(contentsOf: [0x01, 0x00])

            // ICO目录项 (16字节)
            // 图像宽度 (1字节): 32
            icoData.append(0x20)
            // 图像高度 (1字节): 32
            icoData.append(0x20)
            // 颜色数 (1字节): 0表示>=256色
            icoData.append(0x00)
            // 保留字段 (1字节): 0
            icoData.append(0x00)
            // 颜色平面数 (2字节): 1
            icoData.append(contentsOf: [0x01, 0x00])
            // 每像素位数 (2字节): 32
            icoData.append(contentsOf: [0x20, 0x00])
            // 图像数据大小 (4字节)
            let imageSize = pngData.count
            icoData.append(contentsOf: withUnsafeBytes(of: UInt32(imageSize).littleEndian) { Array($0) })
            // 图像数据偏移量 (4字节): 22 (文件头6 + 目录项16)
            icoData.append(contentsOf: withUnsafeBytes(of: UInt32(22).littleEndian) { Array($0) })

            // 添加PNG图像数据
            icoData.append(pngData)

            // 写入ICO文件
            try icoData.write(to: saveTo)

            // 删除临时文件
            try? FileManager.default.removeItem(at: tempPNGPath)

            return true
        } catch {
            MagicMessageProvider.shared.error("生成ICO文件失败：\(error)")
            // 删除临时文件
            try? FileManager.default.removeItem(at: tempPNGPath)
            return false
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
