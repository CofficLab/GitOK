import MagicCore
import SwiftUI
import MagicAlert
import MagicDevice

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
            title: progressText.isEmpty ? "iPhone App Store 截图" : progressText,
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
            MagicMessageProvider.shared.error("没有可用的Banner")
            return
        }

        isGenerating = true
        progressText = "正在生成iPhone App Store截图..."
        defer { 
            isGenerating = false
            progressText = ""
        }

        let tag = Date.nowCompact
        let folderName = "Banner-iPhone-AppStore-Screenshots-\(tag)"

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
            
            progressText = "正在生成 \(description) (\(index + 1)/\(iPhoneDevices.count))..."
            
            let fileName = "iphone-appstore-screenshot-\(device.rawValue)-\(width)x\(height).png"
            let filePath = folderPath.appendingPathComponent(fileName)
            
            // 创建Banner视图进行截图
            let bannerView = createBannerView(device: device)
            
            do {
                try bannerView.snapshot(path: filePath)
                successCount += 1
            } catch {
                MagicMessageProvider.shared.error("生成截图 \(description) 失败: \(error.localizedDescription)")
            }
        }

        // 显示结果
        if successCount == iPhoneDevices.count {
            MagicMessageProvider.shared.success("成功生成 \(successCount) 个iPhone App Store截图")
            // 打开下载文件夹
            NSWorkspace.shared.open(folderPath)
        } else {
            MagicMessageProvider.shared.error("只成功生成了 \(successCount)/\(iPhoneDevices.count) 个截图")
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
        .setInitialTab(BannerPlugin.label)
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .setInitialTab(BannerPlugin.label)
        .hideTabPicker()
        .inRootView()
        .frame(width: 800)
        .frame(height: 1000)
}
