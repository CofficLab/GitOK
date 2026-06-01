import GitOKCoreKit
import SwiftUI

/**
 * Banner PNG格式下载按钮
 * 专门处理Banner PNG格式的下载和生成
 * 支持多种尺寸的PNG Banner文件
 */
struct BannerPNGDownloadButton: View {
    @EnvironmentObject var bannerProvider: BannerProvider
    let template: (any BannerTemplateProtocol)?

    @State private var isGenerating = false
    @State private var progressText = ""

    var body: some View {
        BannerDownloadButton(
            title: progressText.isEmpty ? String(localized: "Download Standard PNG", table: "Banner") : progressText,
            icon: "photo",
            color: .green,
            action: {
                Task {
                    await downloadPNG()
                }
            },
            isDisabled: isGenerating || bannerProvider.banner.path.isEmpty
        )
    }

    @MainActor private func downloadPNG() async {
        guard !bannerProvider.banner.path.isEmpty else {
            MagicMessageProvider.shared.error(String(localized: "No Banners available", table: "Banner"))
            return
        }

        isGenerating = true
        progressText = String(localized: "Generating standard PNG...", table: "Banner")
        defer {
            isGenerating = false
            progressText = ""
        }

        let tag = Date.nowCompact
        let folderName = "Banner-Standard-PNG-\(tag)"

        guard let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
            MagicMessageProvider.shared.error(String(localized: "No access to Downloads folder", table: "Banner"))
            return
        }

        let folderPath = downloadsURL.appendingPathComponent(folderName, isDirectory: true)

        do {
            try FileManager.default.createDirectory(at: folderPath, withIntermediateDirectories: true)
        } catch {
            let msg = String.localizedStringWithFormat(
                String(localized: "Failed to create target directory: %@", table: "Banner"),
                error.localizedDescription
            )
            MagicMessageProvider.shared.error(msg)
            return
        }

        // 为所有设备生成PNG截图
        let allDevices = [MagicDevice.iMac, MagicDevice.MacBook, MagicDevice.iPhoneBig, MagicDevice.iPhoneSmall, MagicDevice.iPad_mini]
        var successCount = 0

        for (index, device) in allDevices.enumerated() {
            let width = Int(device.width)
            let height = Int(device.height)
            let description = "\(width)x\(height) (\(device.description))"

            progressText = String.localizedStringWithFormat(
                String(localized: "Generating %@ (%d/%d)...", table: "Banner"),
                description,
                index + 1,
                allDevices.count
            )

            let fileName = "banner-\(device.rawValue)-\(width)x\(height).png"
            let filePath = folderPath.appendingPathComponent(fileName)

            // 创建Banner视图进行截图
            let bannerView = createBannerView(device: device)

            do {
                try bannerView.snapshot(path: filePath)
                successCount += 1
            } catch {
                let msg = String.localizedStringWithFormat(
                    String(localized: "Failed to generate PNG %@: %@", table: "Banner"),
                    description,
                    error.localizedDescription
                )
                MagicMessageProvider.shared.error(msg)
            }
        }

        // 显示结果
        if successCount == allDevices.count {
            let msg = String.localizedStringWithFormat(
                String(localized: "Successfully generated %d PNG files", table: "Banner"),
                successCount
            )
            MagicMessageProvider.shared.success(msg)
            // 打开下载文件夹
            NSWorkspace.shared.open(folderPath)
        } else {
            let msg = String.localizedStringWithFormat(
                String(localized: "Only successfully generated %d/%d files", table: "Banner"),
                successCount,
                allDevices.count
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
