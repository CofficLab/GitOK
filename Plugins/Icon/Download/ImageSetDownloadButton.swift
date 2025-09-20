import MagicCore
import MagicAlert
import SwiftUI

/**
 * Image Set 下载按钮
 * 生成 Xcode 通用图片资源（imageset），包含 1x/2x/3x 三种比例
 * 以基准点尺寸（basePointSize）为 1x，自动导出 2x/3x 并生成 Contents.json
 */
struct ImageSetDownloadButton: View {
    let iconProvider: IconProvider
    let currentIconAsset: IconAsset?

    /// 基准点尺寸（1x 像素）
    private let basePointSize: Int = 256

    @State private var isGenerating = false
    @State private var progressText = ""

    var body: some View {
        DownloadButton(
            title: progressText.isEmpty ? "下载 Image Set (1x/2x/3x)" : progressText,
            icon: "rectangle.3.group",
            color: .orange,
            action: {
                Task { await downloadImageSet() }
            },
            isDisabled: isGenerating || currentIconAsset == nil || iconProvider.currentData == nil
        )
    }

    @MainActor private func downloadImageSet() async {
        guard let iconAsset = currentIconAsset else {
            MagicMessageProvider.shared.error("没有可用的图标资源")
            return
        }

        isGenerating = true
        progressText = "正在生成 Image Set..."
        defer {
            isGenerating = false
            progressText = ""
        }

        let tag = Date.nowCompact
        let folderName = "ImageSet-\(tag).imageset"

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

        // 生成 1x / 2x / 3x PNG
        let scales: [(label: String, multiplier: Int)] = [("1x", 1), ("2x", 2), ("3x", 3)]
        var successCount = 0

        for (index, scale) in scales.enumerated() {
            let px = basePointSize * scale.multiplier
            progressText = "生成 \(px)x\(px) (\(index + 1)/\(scales.count))"
            if await generatePNG(size: px, scaleLabel: scale.label, folderPath: folderPath, tag: tag, iconAsset: iconAsset) {
                successCount += 1
            }
        }

        // 生成 Contents.json
        await generateContentJson(folderPath: folderPath, tag: tag)

        if successCount == scales.count {
            MagicMessageProvider.shared.success("Image Set 已保存到下载目录")
        } else {
            MagicMessageProvider.shared.warning("Image Set 生成完成，但有部分失败\n保存位置：\(folderPath.path)\n成功：\(successCount)/\(scales.count)")
        }
    }

    @MainActor private func generatePNG(size: Int, scaleLabel: String, folderPath: URL, tag: String, iconAsset: IconAsset) async -> Bool {
        guard let iconData = iconProvider.currentData else {
            MagicMessageProvider.shared.error("没有可用的图标数据")
            return false
        }

        let fileName = "\(tag)-\(scaleLabel).png"
        let saveTo = folderPath.appendingPathComponent(fileName)

        let success = await IconRenderer.snapshotIcon(iconData: iconData, iconAsset: iconAsset, size: size, savePath: saveTo)
        return success
    }

    @MainActor private func generateContentJson(folderPath: URL, tag: String) async {
        let images: [[String: Any]] = [
            ["filename": "\(tag)-1x.png", "idiom": "universal", "scale": "1x"],
            ["filename": "\(tag)-2x.png", "idiom": "universal", "scale": "2x"],
            ["filename": "\(tag)-3x.png", "idiom": "universal", "scale": "3x"],
        ]

        let jsonData = try! JSONSerialization.data(
            withJSONObject: [
                "images": images,
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
            }
        } catch {
            MagicMessageProvider.shared.error("生成 Contents.json 失败：\(error)")
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
            .hideTabPicker()
            .hideProjectActions()
            .hideSidebar()
    }
    .frame(width: 800)
    .frame(height: 1000)
}


