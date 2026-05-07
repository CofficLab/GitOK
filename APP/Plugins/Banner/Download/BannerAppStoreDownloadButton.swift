import MagicAlert
import MagicDevice
import MagicKit
import SwiftUI

/**
 * Banner Mac App Store截图下载按钮
 * 专门生成符合Mac App Store要求的截图尺寸
 * 支持Apple官方要求的16:10宽高比截图
 */
struct BannerAppStoreDownloadButton: View {
    @EnvironmentObject var bannerProvider: BannerProvider
    let template: (any BannerTemplateProtocol)?

    @State private var isGenerating = false
    @State private var progressText = ""

    var body: some View {
        BannerDownloadButton(
            title: progressText.isEmpty ? String(localized: "Mac App Store 截图", table: "Banner") : progressText,
            icon: "app.badge",
            color: .blue,
            action: {
                Task {
                    await downloadAppStoreScreenshots()
                }
            },
            isDisabled: isGenerating || bannerProvider.banner.path.isEmpty
        )
    }

    @MainActor private func downloadAppStoreScreenshots() async {
        guard !bannerProvider.banner.path.isEmpty else {
            MagicMessageProvider.shared.error(String(localized: "没有可用的Banner", table: "Banner"))
            return
        }

        isGenerating = true
        progressText = String(localized: "正在生成App Store截图...", table: "Banner")
        defer {
            isGenerating = false
            progressText = ""
        }

        let tag = Date.nowCompact
        let folderName = "Banner-AppStore-Screenshots-\(tag)"

        guard let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
            MagicMessageProvider.shared.error(String(localized: "无权访问下载文件夹", table: "Banner"))
            return
        }

        let folderPath = downloadsURL.appendingPathComponent(folderName, isDirectory: true)

        do {
            try FileManager.default.createDirectory(at: folderPath, withIntermediateDirectories: true)
        } catch {
            let msg = String.localizedStringWithFormat(
                String(localized: "创建目标目录失败：%@", table: "Banner"),
                error.localizedDescription
            )
            MagicMessageProvider.shared.error(msg)
            return
        }

        // 为所有Mac设备生成App Store截图
        let macDevices = [MagicDevice.iMac, MagicDevice.MacBook]
        var appStoreSizes: [(Int, Int, String)] = []

        for device in macDevices {
            let width = Int(device.width)
            let height = Int(device.height)
            appStoreSizes.append((width, height, "\(width)x\(height) (\(device.description))"))
        }
        var successCount = 0

        for (index, device) in macDevices.enumerated() {
            let width = Int(device.width)
            let height = Int(device.height)
            let description = "\(width)x\(height) (\(device.description))"

            progressText = String.localizedStringWithFormat(
                String(localized: "正在生成 %@ (%d/%d)...", table: "Banner"),
                description,
                index + 1,
                macDevices.count
            )

            let fileName = "appstore-screenshot-\(device.rawValue)-\(width)x\(height).png"
            let filePath = folderPath.appendingPathComponent(fileName)

            // 创建Banner视图进行截图
            let bannerView = createBannerView(device: device)

            do {
                try bannerView.snapshot(path: filePath)
                successCount += 1
            } catch {
                let msg = String.localizedStringWithFormat(
                    String(localized: "生成截图 %@ 失败: %@", table: "Banner"),
                    description,
                    error.localizedDescription
                )
                MagicMessageProvider.shared.error(msg)
            }
        }

        // 显示结果
        if successCount == macDevices.count {
            let msg = String.localizedStringWithFormat(
                String(localized: "成功生成 %d 个App Store截图", table: "Banner"),
                successCount
            )
            MagicMessageProvider.shared.success(msg)
            // 打开下载文件夹
            NSWorkspace.shared.open(folderPath)
        } else {
            let msg = String.localizedStringWithFormat(
                String(localized: "只成功生成了 %d/%d 个截图", table: "Banner"),
                successCount,
                macDevices.count
            )
            MagicMessageProvider.shared.error(msg)
        }
    }

    @ViewBuilder
    private func createBannerView(device: MagicDevice) -> some View {
        if let template = template {
            // 使用当前选择的模板
            template.createPreviewView()
                .frame(width: device.width, height: device.height)
        } else {
            // 后备方案：使用默认的经典模板
            ClassicBannerLayout()
                .environmentObject(bannerProvider)
                .frame(width: device.width, height: device.height)
        }
    }
}

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .setInitialTab("Banner")
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .hideTabPicker()
        .inRootView()
        .frame(width: 800)
        .frame(height: 1000)
}
