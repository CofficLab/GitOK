import MagicCore
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
            title: progressText.isEmpty ? "下载 标准 PNG" : progressText,
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
            MagicMessageProvider.shared.error("没有可用的Banner")
            return
        }

        isGenerating = true
        progressText = "正在生成标准PNG..."
        defer { 
            isGenerating = false
            progressText = ""
        }

        let tag = Date.nowCompact
        let folderName = "Banner-Standard-PNG-\(tag)"

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

        // 为所有设备生成PNG截图
        let allDevices = [Device.iMac, Device.MacBook, Device.iPhoneBig, Device.iPhoneSmall, Device.iPad]
        var successCount = 0

        for (index, device) in allDevices.enumerated() {
            let width = Int(device.width)
            let height = Int(device.height)
            let description = "\(width)x\(height) (\(device.description))"
            
            progressText = "正在生成 \(description) (\(index + 1)/\(allDevices.count))..."
            
            let fileName = "banner-\(device.rawValue)-\(width)x\(height).png"
            let filePath = folderPath.appendingPathComponent(fileName)
            
            // 创建Banner视图进行截图
            let bannerView = createBannerView(device: device)
            
            let result = MagicImage.snapshot(
                bannerView,
                path: filePath
            )
            
            // 检查文件是否成功生成
            if FileManager.default.fileExists(atPath: filePath.path) {
                successCount += 1
            }
        }

        // 显示结果
        if successCount == allDevices.count {
            MagicMessageProvider.shared.success("成功生成 \(successCount) 个PNG文件")
            // 打开下载文件夹
            NSWorkspace.shared.open(folderPath)
        } else {
            MagicMessageProvider.shared.error("只成功生成了 \(successCount)/\(allDevices.count) 个文件")
        }
    }
    
    @ViewBuilder
    private func createBannerView(device: Device) -> some View {
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
    RootView {
        ContentLayout()
            .setInitialTab(BannerPlugin.label)
            .hideSidebar()
            .hideTabPicker()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .setInitialTab(BannerPlugin.label)
            .hideSidebar()
            .hideTabPicker()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 1000)
}
