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
            title: progressText.isEmpty ? String(localized: "iPhone App Store Screenshots", table: "Banner") : progressText,
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
            MagicMessageProvider.shared.error(String(localized: "No Banners available", table: "Banner"))
            return
        }

        isGenerating = true
        progressText = String(localized: "Generating iPhone App Store screenshots...", table: "Banner")
        defer {
            isGenerating = false
            progressText = ""
        }

        let tag = Date.nowCompact
        let folderName = "Banner-iPhone-AppStore-Screenshots-\(tag)"

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
                String(localized: "Generating %@ (%d/%d)...", table: "Banner"),
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
                    String(localized: "Failed to generate screenshot %@: %@", table: "Banner"),
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
                        String(localized: "Successfully generated %d iPhone App Store screenshots", table: "Banner"),
                        successCount
                    )
                )
            } else {
                MagicMessageProvider.shared.warning(
                    String.localizedStringWithFormat(
                        String(localized: "Only successfully generated %d/%d screenshots", table: "Banner"),
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
