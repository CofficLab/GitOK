import GitOKCoreKit
import MagicAlert
import GitOKSupportKit
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
            title: progressText.isEmpty ? BannerPluginLocalization.string("Mac App Store Screenshots") : progressText,
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
            MagicMessageProvider.shared.error(BannerPluginLocalization.string("No Banners available"))
            return
        }

        isGenerating = true
        progressText = BannerPluginLocalization.string("Generating App Store screenshots...")
        defer {
            isGenerating = false
            progressText = ""
        }

        let tag = Date.nowCompact
        let folderName = "Banner-AppStore-Screenshots-\(tag)"

        guard let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
            MagicMessageProvider.shared.error(BannerPluginLocalization.string("No access to Downloads folder"))
            return
        }

        let folderPath = downloadsURL.appendingPathComponent(folderName, isDirectory: true)

        do {
            try FileManager.default.createDirectory(at: folderPath, withIntermediateDirectories: true)
        } catch {
            let msg = String.localizedStringWithFormat(
                BannerPluginLocalization.string("Failed to create target directory: %@"),
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
                BannerPluginLocalization.string("Generating %@ (%d/%d)..."),
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
                    BannerPluginLocalization.string("Failed to generate screenshot %@: %@"),
                    description,
                    error.localizedDescription
                )
                MagicMessageProvider.shared.error(msg)
            }
        }

        // 显示结果
        if successCount == macDevices.count {
            let msg = String.localizedStringWithFormat(
                BannerPluginLocalization.string("Successfully generated %d App Store screenshots"),
                successCount
            )
            MagicMessageProvider.shared.success(msg)
            // 打开下载文件夹
            NSWorkspace.shared.open(folderPath)
        } else {
            let msg = String.localizedStringWithFormat(
                BannerPluginLocalization.string("Only successfully generated %d/%d screenshots"),
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
