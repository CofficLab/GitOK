import MagicCore
import MagicAlert
import SwiftUI

/**
 * PNG 格式下载按钮
 * 专门处理 PNG 格式图标的下载和生成
 * 支持多种尺寸的 PNG 图标文件
 */
struct PNGDownloadButton: View {
    let iconProvider: IconProvider
    let currentIconAsset: IconAsset?
    
    @State private var isGenerating = false
    @State private var progressText = ""

    var body: some View {
        DownloadButton(
            title: progressText.isEmpty ? "下载 PNG 格式" : progressText,
            icon: "photo",
            color: .green,
            action: {
                Task {
                    await downloadPNG()
                }
            },
            isDisabled: isGenerating || currentIconAsset == nil || iconProvider.currentData == nil
        )
    }

    @MainActor private func downloadPNG() async {
        guard let iconAsset = currentIconAsset else {
            MagicMessageProvider.shared.error("没有可用的图标资源")
            return
        }

        isGenerating = true
        progressText = "正在生成 PNG 格式..."
        defer { 
            isGenerating = false
            progressText = ""
        }

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
        var successCount = 0

        for (index, size) in sizes.enumerated() {
            progressText = "正在生成 PNG \(size)×\(size) (\(index + 1)/\(sizes.count))"
            if await generatePNG(size: size, folderPath: folderPath, tag: tag, iconAsset: iconAsset) {
                successCount += 1
            }
        }

        if successCount == sizes.count {
            MagicMessageProvider.shared.success("PNG格式已保存到下载目录")
        } else {
            MagicMessageProvider.shared.warning("PNG格式生成完成，但有部分失败\n保存位置：\(folderPath.path)\n成功：\(successCount)/\(sizes.count)")
        }
    }

    @MainActor private func generatePNG(size: Int, folderPath: URL, tag: String, iconAsset: IconAsset) async -> Bool {
        guard let iconData = iconProvider.currentData else {
            MagicMessageProvider.shared.error("没有可用的图标数据")
            return false
        }

        let fileName = "\(tag)-\(size)x\(size).png"
        let saveTo = folderPath.appendingPathComponent(fileName)

        do {
            try await IconRenderer.snapshot(iconData: iconData, iconAsset: iconAsset, size: size, savePath: saveTo)
            return true
        } catch {
            MagicMessageProvider.shared.error("尺寸 \(size)x\(size) 生成失败: \(error.localizedDescription)")
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
