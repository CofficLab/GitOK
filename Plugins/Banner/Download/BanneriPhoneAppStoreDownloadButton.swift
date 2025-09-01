import MagicCore
import SwiftUI

/**
 * Banner iPhone App Store截图下载按钮
 * 专门生成符合iOS App Store要求的截图尺寸
 * 支持最新iPhone设备的截图规格
 */
struct BanneriPhoneAppStoreDownloadButton: View {
    @EnvironmentObject var bannerProvider: BannerProvider
    
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

        // 根据当前设备类型获取合适的iPhone App Store截图尺寸
        let currentDevice = bannerProvider.banner.getDevice()
        let iPhoneAppStoreSizes: [(Int, Int, String)]
        
        if currentDevice.isiPhone {
            // iPhone设备：只生成当前设备的原始尺寸，这是最合适的
            let deviceWidth = Int(currentDevice.width)
            let deviceHeight = Int(currentDevice.height)
            iPhoneAppStoreSizes = [
                (deviceWidth, deviceHeight, "\(deviceWidth)x\(deviceHeight) (\(currentDevice.description))")
            ]
        } else {
            // 非iPhone设备：生成标准iPhone App Store尺寸作为通用方案
            iPhoneAppStoreSizes = [
                (1290, 2796, "1290x2796 (通用iPhone尺寸)")
            ]
        }
        var successCount = 0

        for (index, (width, height, description)) in iPhoneAppStoreSizes.enumerated() {
            progressText = "正在生成 \(description) (\(index + 1)/\(iPhoneAppStoreSizes.count))..."
            
            let fileName = "iphone-appstore-\(width)x\(height).png"
            let filePath = folderPath.appendingPathComponent(fileName)
            
            // 创建Banner视图进行截图
            let bannerView = createBannerView(width: CGFloat(width), height: CGFloat(height))
            
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
        let readmeContent = generateiPhoneReadmeContent()
        let readmePath = folderPath.appendingPathComponent("README.txt")
        do {
            try readmeContent.write(to: readmePath, atomically: true, encoding: .utf8)
        } catch {
            // 忽略README写入失败，不影响主要功能
        }

        // 显示结果
        if successCount == iPhoneAppStoreSizes.count {
            MagicMessageProvider.shared.success("成功生成 \(successCount) 个iPhone App Store截图")
            // 打开下载文件夹
            NSWorkspace.shared.open(folderPath)
        } else {
            MagicMessageProvider.shared.error("只成功生成了 \(successCount)/\(iPhoneAppStoreSizes.count) 个截图")
        }
    }
    
    @ViewBuilder
    private func createBannerView(width: CGFloat, height: CGFloat) -> some View {
        BannerLayout()
            .environmentObject(bannerProvider)
            .frame(width: width, height: height)
    }
    
    private func generateiPhoneReadmeContent() -> String {
        return """
        iPhone App Store 截图说明
        ========================
        
        本文件夹包含符合iOS App Store要求的iPhone截图文件：
        
        📱 支持的设备尺寸（竖屏格式）：
        
        🆕 最新设备 (必需提供)：
        • 1290x2796 - iPhone 16 Pro Max (6.9") [推荐]
        • 1284x2778 - iPhone 15 Pro Max (6.5") [必需]
        • 1179x2556 - iPhone 16 Pro (6.3")
        • 1170x2532 - iPhone 15 Pro (6.1")
        
        📱 经典设备 (兼容性支持)：
        • 1242x2208 - iPhone 8 Plus (5.5")
        • 750x1334 - iPhone SE (4.7")
        • 640x1136 - iPhone SE 1st Gen (4.0")
        
        📋 使用说明：
        1. Apple要求至少提供6.9"或6.5"设备的截图
        2. 6.9"截图将自动适配到其他设备
        3. 在App Store Connect中上传对应尺寸的截图
        4. 确保截图内容适合竖屏显示
        
        ⚠️ 重要提示：
        • 必须提供6.9"或6.5"设备截图
        • 截图必须是实际应用内容
        • 建议使用最高分辨率版本
        • 遵循iOS设计规范和审核指南
        
        💡 优化建议：
        • 重点关注1290x2796和1284x2778尺寸
        • 确保文字和UI元素在小屏幕上清晰可读
        • 考虑不同设备的安全区域
        
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
            .hideTabPicker()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 1000)
}
