import MagicCore
import SwiftUI

/**
 * Banner PNG格式下载按钮
 * 专门处理Banner PNG格式的下载和生成
 * 支持多种尺寸的PNG Banner文件
 */
struct BannerPNGDownloadButton: View {
    @EnvironmentObject var bannerProvider: BannerProvider
    
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

        // 生成不同尺寸的标准PNG文件
        let sizes = [(1200, 630), (800, 420), (600, 315), (400, 210)]
        var successCount = 0

        for (index, (width, height)) in sizes.enumerated() {
            progressText = "正在生成 \(width)x\(height) 标准PNG (\(index + 1)/\(sizes.count))..."
            
            let fileName = "banner-std-\(width)x\(height).png"
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

        // 显示结果
        if successCount == sizes.count {
            MagicMessageProvider.shared.success("成功生成 \(successCount) 个标准PNG文件")
            // 打开下载文件夹
            NSWorkspace.shared.open(folderPath)
        } else {
            MagicMessageProvider.shared.error("只成功生成了 \(successCount)/\(sizes.count) 个文件")
        }
    }
    
    @ViewBuilder
    private func createBannerView(width: CGFloat, height: CGFloat) -> some View {
        BannerLayout()
            .environmentObject(bannerProvider)
            .frame(width: width, height: height)
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
