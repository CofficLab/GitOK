import SwiftUI
import GitOKSupportKit
import GitOKCoreKit
import MagicAlert

/**
 * Banner iPhone App Store截图下载按钮
 * 专门生成符合iOS App Store要求的截图尺寸
 * 支持最新iPhone设备的截图规格
 */
struct BanneriPhoneAppStoreDownloadButton: View {
    @EnvironmentObject var bannerProvider: BannerProvider
    let template: (any BannerTemplateProtocol)?

    @State private var isGenerating = false
    @State private var progressText = ""

    var body: some View {
        BannerDownloadButton(
            title: progressText.isEmpty ? BannerPluginLocalization.string("iPhone App Store Screenshots") : progressText,
            icon: "iphone",
            color: .purple,
            action: {
                Task {
                    await downloadiPhoneAppStoreScreenshots()
                }
            },
            isDisabled: isGenerating || bannerProvider.banner.path.isEmpty
        )
    }

    @MainActor private func downloadiPhoneAppStoreScreenshots() async {
        guard !bannerProvider.banner.path.isEmpty else {
            MagicMessageProvider.shared.error(BannerPluginLocalization.string("No Banners available"))
            return
        }

        isGenerating = true
        progressText = BannerPluginLocalization.string("Generating iPhone App Store screenshots...")
        defer {
            isGenerating = false
            progressText = ""
        }

        let tag = Date.nowCompact
        let folderName = "Banner-iPhone-AppStore-Screenshots-\(tag)"

        guard let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
            MagicMessageProvider.shared.error(BannerPluginLocalization.string("No access to Downloads folder"))
            return
        }

        let folderPath = downloadsURL.appendingPathComponent(folderName, isDirectory: true)

        do {
            try await BannerDownloadFileOperations.createDirectory(folderPath)
        } catch {
            let msg = String.localizedStringWithFormat(
                BannerPluginLocalization.string("Failed to create target directory: %@"),
                error.localizedDescription
            )
            MagicMessageProvider.shared.error(msg)
            return
        }

        // 为所有iPhone设备生成App Store截图
        let iPhoneDevices = [MagicDevice.iPhoneBig, MagicDevice.iPhoneSmall]
        var iPhoneAppStoreSizes: [(Int, Int, String)] = []

        for device in iPhoneDevices {
            let width = Int(device.width)
            let height = Int(device.height)
            iPhoneAppStoreSizes.append((width, height, "\(width)x\(height) (\(device.description))"))
        }
        var successCount = 0

        for (index, device) in iPhoneDevices.enumerated() {
            let width = Int(device.width)
            let height = Int(device.height)
            let description = "\(width)x\(height) (\(device.description))"

            progressText = String.localizedStringWithFormat(
                BannerPluginLocalization.string("Generating %@ (%d/%d)..."),
                description,
                index + 1,
                iPhoneDevices.count
            )

            let fileName = "iphone-appstore-screenshot-\(device.rawValue)-\(width)x\(height).png"
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

        if successCount > 0 {
            if successCount == iPhoneDevices.count {
                MagicMessageProvider.shared.success(
                    String.localizedStringWithFormat(
                        BannerPluginLocalization.string("Successfully generated %d iPhone App Store screenshots"),
                        successCount
                    )
                )
            } else {
                MagicMessageProvider.shared.warning(
                    String.localizedStringWithFormat(
                        BannerPluginLocalization.string("Only successfully generated %d/%d screenshots"),
                        successCount,
                        iPhoneDevices.count
                    )
                )
            }
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
