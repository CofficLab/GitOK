import MagicCore
import SwiftUI

/**
 * Xcode图标生成器组件
 * 专门用于生成Xcode项目所需的iOS和macOS图标集合
 * 支持多种尺寸和平台的图标生成，包含完整的Contents.json配置
 */
struct XcodeMaker: View {
    let icon: IconModel
    @State private var imageSet: [Any] = []
    @State private var folderPath: URL? = nil

    private let tag = Date.nowCompact
    private var folderName: String { "XcodeIcons-\(tag).appiconset" }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Xcode 图标")
                    .font(.headline)

                Button("下载") {
                    generateXcodeIcons()
                }
            }
            HStack(spacing: 20) {
                // macOS 预览
                VStack {
                    Text("macOS")
                        .font(.caption)
                        .fontWeight(.medium)
                    IconPreview(icon: icon, platform: "macOS")
                        .frame(width: 64, height: 64)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(12)
                }

                // iOS 预览
                VStack {
                    Text("iOS")
                        .font(.caption)
                        .fontWeight(.medium)
                    IconPreview(icon: icon, platform: "iOS")
                        .frame(width: 64, height: 64)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }

    @MainActor private func generateXcodeIcons() {
        imageSet = []

        let (message, path) = getFolderPath()
        if path == nil {
            MagicMessageProvider.shared.error("错误：\(message)")
            return
        }

        folderPath = path

        // 生成macOS图标
        generateMacOSIcons()

        // 生成iOS图标
        generateIOSIcons()

        // 生成Contents.json文件
        generateContentJson()

        MagicMessageProvider.shared.success("Xcode图标已生成到：\(folderPath?.path ?? "")")
    }

    @MainActor private func generateMacOSIcons() {
        guard let folderPath = folderPath else { return }

        for size in [16, 32, 64, 128, 256, 512, 1024] {
            let fileName = "\(tag)-macOS-\(size)x\(size).png"
            let saveTo = folderPath.appendingPathComponent(fileName)

            _ = MagicImage.snapshot(
                MagicImage.makeImage(IconPreview(icon: icon, platform: "macOS"))
                    .resizable()
                    .scaledToFit()
                    .frame(width: CGFloat(size), height: CGFloat(size)),
                path: saveTo
            )

            if ![64, 1024].contains(size) {
                imageSet.append([
                    "filename": fileName,
                    "idiom": "mac",
                    "scale": "1x",
                    "size": "\(size)x\(size)",
                ])
            }

            if [64, 256, 512, 1024].contains(size) {
                imageSet.append([
                    "filename": fileName,
                    "idiom": "mac",
                    "scale": "2x",
                    "size": "\(size / 2)x\(size / 2)",
                ])
            }
        }
    }

    @MainActor private func generateIOSIcons() {
        guard let folderPath = folderPath else { return }

        let size = 1024
        let fileName = "\(tag)-iOS-\(size)x\(size).png"
        let saveTo = folderPath.appendingPathComponent(fileName)

        _ = MagicImage.snapshot(
            MagicImage.makeImage(IconPreview(icon: icon, platform: "iOS"))
                .resizable()
                .scaledToFit()
                .frame(width: CGFloat(size), height: CGFloat(size)),
            path: saveTo
        )

        imageSet.append([
            "filename": fileName,
            "idiom": "universal",
            "platform": "ios",
            "size": "1024x1024",
        ])
    }

    @MainActor private func generateContentJson() {
        guard let folderPath = folderPath else { return }

        let jsonData = try! JSONSerialization.data(
            withJSONObject: [
                "images": imageSet,
                "info": [
                    "author": "xcode",
                    "version": 1,
                ],
            ],
            options: [.prettyPrinted]
        )

        try! String(data: jsonData, encoding: .utf8)!.write(
            to: folderPath.appendingPathComponent("Contents.json"),
            atomically: true,
            encoding: .utf8
        )
    }

    private func getFolderPath() -> (message: String, path: URL?) {
        guard let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
            return ("无权访问下载文件夹", nil)
        }

        let folderPath = downloadsURL.appendingPathComponent(folderName, isDirectory: true)

        if !FileManager.default.fileExists(atPath: folderPath.path) {
            do {
                try FileManager.default.createDirectory(
                    at: folderPath,
                    withIntermediateDirectories: true
                )
            } catch {
                return ("创建目标目录失败：\(error)", nil)
            }
        }

        return ("成功", folderPath)
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout().setInitialTab("Icon")
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 800)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout().setInitialTab("Icon")
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
