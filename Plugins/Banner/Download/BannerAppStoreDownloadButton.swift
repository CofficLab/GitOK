import MagicCore
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
            title: progressText.isEmpty ? "Mac App Store 截图" : progressText,
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
            MagicMessageProvider.shared.error("没有可用的Banner")
            return
        }

        isGenerating = true
        progressText = "正在生成App Store截图..."
        defer { 
            isGenerating = false
            progressText = ""
        }

        let tag = Date.nowCompact
        let folderName = "Banner-AppStore-Screenshots-\(tag)"

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

        // 为所有Mac设备生成App Store截图
        let macDevices = [Device.iMac, Device.MacBook]
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
            
            progressText = "正在生成 \(description) (\(index + 1)/\(macDevices.count))..."
            
            let fileName = "appstore-screenshot-\(device.rawValue)-\(width)x\(height).png"
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

        // 生成说明文件
        let readmeContent = generateReadmeContent()
        let readmePath = folderPath.appendingPathComponent("README.txt")
        do {
            try readmeContent.write(to: readmePath, atomically: true, encoding: .utf8)
        } catch {
            // 忽略README写入失败，不影响主要功能
        }

        // 显示结果
        if successCount == macDevices.count {
            MagicMessageProvider.shared.success("成功生成 \(successCount) 个App Store截图")
            // 打开下载文件夹
            NSWorkspace.shared.open(folderPath)
        } else {
            MagicMessageProvider.shared.error("只成功生成了 \(successCount)/\(macDevices.count) 个截图")
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
    
    private func generateReadmeContent() -> String {
        return """
        Mac App Store 截图说明
        =====================
        
        本文件夹包含符合Mac App Store要求的截图文件：
        
        📱 支持的尺寸（16:10 宽高比）：
        • 2880x1800 像素 - Retina 5K显示器 (推荐)
        • 2560x1600 像素 - Retina 4K显示器
        • 1440x900 像素 - 标准分辨率
        • 1280x800 像素 - 最小要求
        
        📋 使用说明：
        1. 选择适合你应用的截图尺寸
        2. 在App Store Connect中上传截图
        3. 确保截图内容清晰、美观
        4. 遵循Apple的App Store审核指南
        
        ⚠️ 注意事项：
        • 所有截图必须是实际应用内容
        • 不得包含虚假或误导性信息
        • 建议使用高分辨率版本以获得最佳显示效果
        
        生成时间: \(Date().formatted())
        """
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .setInitialTab(BannerPlugin.label)
            .hideSidebar()
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
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
