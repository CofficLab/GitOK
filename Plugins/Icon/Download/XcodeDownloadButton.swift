import MagicCore
import MagicAlert
import SwiftUI

/**
 * Xcode 格式下载按钮
 * 支持选择 Xcode 16 或 26 版本
 * Xcode 16: 自动调整内边距
 * Xcode 26: 使用用户设置的内边距
 */
struct XcodeDownloadButton: View {
    let iconProvider: IconProvider
    let currentIconAsset: IconAsset?

    @State private var isGenerating = false
    @State private var progressText = ""
    @State private var selectedVersion: XcodeVersion = .version26
    
    enum XcodeVersion: String, CaseIterable {
        case version16 = "Xcode 16"
        case version26 = "Xcode 26"
        
        var color: Color {
            switch self {
            case .version16:
                return .blue
            case .version26:
                return .purple
            }
        }
    }

    var body: some View {
        DownloadButton(
            title: progressText.isEmpty ? "下载 \(selectedVersion.rawValue) 格式" : progressText,
            icon: "applelogo",
            color: selectedVersion.color,
            action: {
                Task {
                    await downloadXcode()
                }
            },
            isDisabled: isGenerating || currentIconAsset == nil || iconProvider.currentData == nil
        ) {
            // 版本选择器
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Picker("", selection: $selectedVersion) {
                        ForEach(XcodeVersion.allCases, id: \.self) { version in
                            Text(version.rawValue)
                                .tag(version)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(maxWidth: 200)
                    
                    Spacer()
                }
                
                // 版本规则说明
                VStack(alignment: .leading, spacing: 4) {
                    if selectedVersion == .version16 {
                        Text("• 自动调整内边距为 0.1")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("• 保持原有圆角和透明度设置")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("• 使用用户自定义内边距")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("• 强制移除圆角 (cornerRadius = 0)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("• 强制不透明 (opacity = 1.0)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    @MainActor private func downloadXcode() async {
        guard let iconAsset = currentIconAsset else {
            MagicMessageProvider.shared.error("没有可用的图标资源")
            return
        }

        isGenerating = true
        progressText = "正在生成 \(selectedVersion.rawValue) 图标集..."
        defer {
            isGenerating = false
            progressText = ""
        }

        let tag = Date.nowCompact
        let folderName = "\(selectedVersion.rawValue.replacingOccurrences(of: " ", with: ""))Icons-\(tag).appiconset"

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

        // 生成macOS图标
        await generateMacOSIcons(folderPath: folderPath, tag: tag, iconAsset: iconAsset)

        // 生成iOS图标
        await generateIOSIcons(folderPath: folderPath, tag: tag, iconAsset: iconAsset)

        // 生成Contents.json文件
        await generateContentJson(folderPath: folderPath, tag: tag)

        // 生成README文件
        await generateReadmeFile(folderPath: folderPath, tag: tag)

        MagicMessageProvider.shared.success("\(selectedVersion.rawValue) 图标集已存储到下载目录")
    }

    @MainActor private func generateMacOSIcons(folderPath: URL, tag: String, iconAsset: IconAsset) async {
        guard let iconData = iconProvider.currentData else {
            MagicMessageProvider.shared.error("没有可用的图标数据")
            return
        }
        
        // 创建用于导出的数据副本
        var exportData = iconData
        
        // 根据版本选择是否调整内边距、圆角和透明度
        if selectedVersion == .version16 {
            // Xcode 16: 自动调整内边距
            let originalPadding = exportData.padding
            let standardPadding = 0.1
            
            if originalPadding != standardPadding {
                exportData.padding = standardPadding
            }
        } else {
            // Xcode 26: 移除圆角，强制不透明，使用用户设置的内边距
            exportData.cornerRadius = 0
            exportData.opacity = 1.0
        }

        // 基础尺寸
        let sizes = [16, 32, 128, 256, 512]
        // @2x 尺寸
        let retinaSizes = [32, 64, 256, 512, 1024]

        // 生成基础尺寸图标
        for (index, size) in sizes.enumerated() {
            progressText = "正在生成 macOS \(size)×\(size) (\(index + 1)/\(sizes.count * 2))"
                        let fileName = "\(tag)-macOS-\(size)x\(size).png"
                        let saveTo = folderPath.appendingPathComponent(fileName)
            do {
                try await IconRenderer.snapshot(iconData: exportData, iconAsset: iconAsset, size: size, savePath: saveTo)
            } catch {
                MagicMessageProvider.shared.error("❌ 生成 \(fileName) 失败: \(error.localizedDescription)")
            }
        }

        // 生成 @2x 尺寸图标
        for (index, size) in retinaSizes.enumerated() {
            progressText = "正在生成 macOS \(sizes[index])×\(sizes[index])@2x (\(index + sizes.count + 1)/\(sizes.count * 2))"
            let fileName = "\(tag)-macOS-\(sizes[index])x\(sizes[index])@2x.png"
            let saveTo = folderPath.appendingPathComponent(fileName)

            do {
                try await IconRenderer.snapshot(iconData: exportData, iconAsset: iconAsset, size: size, savePath: saveTo)
            } catch {
                MagicMessageProvider.shared.error("❌ 生成 \(fileName) 失败: \(error.localizedDescription)")
            }
        }
    }

    @MainActor private func generateIOSIcons(folderPath: URL, tag: String, iconAsset: IconAsset) async {
        guard let iconData = iconProvider.currentData else {
            MagicMessageProvider.shared.error("没有可用的图标数据")
            return
        }

        progressText = "正在生成 iOS 1024×1024..."
        let size = 1024
        let fileName = "\(tag)-iOS-\(size)x\(size).png"
        let saveTo = folderPath.appendingPathComponent(fileName)

        // 创建用于导出的数据副本
        var exportData = iconData
        
        // 根据版本选择是否调整内边距、圆角和透明度
        if selectedVersion == .version16 {
            exportData.padding = 0  // Xcode 16: iOS图标不需要padding
            exportData.opacity = 1.0  // Xcode 16: 强制不透明
            // Xcode 16: 保持原有圆角设置
        } else {
            // Xcode 26: 移除圆角，强制不透明，使用用户设置的内边距
            exportData.cornerRadius = 0
            exportData.opacity = 1.0
        }

        do {
            try await IconRenderer.snapshot(iconData: exportData, iconAsset: iconAsset, size: size, savePath: saveTo)
        } catch {
            MagicMessageProvider.shared.error("❌ 生成 \(fileName) 失败: \(error.localizedDescription)")
        }
    }

    @MainActor private func generateContentJson(folderPath: URL, tag: String) async {
        let imageSet: [[String: Any]] = [
            // macOS 1x
            ["filename": "\(tag)-macOS-16x16.png", "idiom": "mac", "scale": "1x", "size": "16x16"],
            ["filename": "\(tag)-macOS-32x32.png", "idiom": "mac", "scale": "1x", "size": "32x32"],
            ["filename": "\(tag)-macOS-128x128.png", "idiom": "mac", "scale": "1x", "size": "128x128"],
            ["filename": "\(tag)-macOS-256x256.png", "idiom": "mac", "scale": "1x", "size": "256x256"],
            ["filename": "\(tag)-macOS-512x512.png", "idiom": "mac", "scale": "1x", "size": "512x512"],
            // macOS @2x
            ["filename": "\(tag)-macOS-16x16@2x.png", "idiom": "mac", "scale": "2x", "size": "16x16"],
            ["filename": "\(tag)-macOS-32x32@2x.png", "idiom": "mac", "scale": "2x", "size": "32x32"],
            ["filename": "\(tag)-macOS-128x128@2x.png", "idiom": "mac", "scale": "2x", "size": "128x128"],
            ["filename": "\(tag)-macOS-256x256@2x.png", "idiom": "mac", "scale": "2x", "size": "256x256"],
            ["filename": "\(tag)-macOS-512x512@2x.png", "idiom": "mac", "scale": "2x", "size": "512x512"],
            // iOS
            ["filename": "\(tag)-iOS-1024x1024.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"],
        ]

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

        do {
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                try jsonString.write(
                    to: folderPath.appendingPathComponent("Contents.json"),
                    atomically: true,
                    encoding: .utf8
                )
            }
        } catch {
            MagicMessageProvider.shared.error("生成 Contents.json 失败：\(error)")
        }
    }

    @MainActor private func generateReadmeFile(folderPath: URL, tag: String) async {
        let fileName = "README.md"
        let saveTo = folderPath.appendingPathComponent(fileName)

        let readmeContent = """
        # \(selectedVersion.rawValue) 图标集使用说明

        ## 文件说明

        这个 `.appiconset` 文件夹包含了适用于 iOS 和 macOS 应用的所有图标文件。
        \(selectedVersion == .version16 ? "此版本自动调整内边距以确保最佳显示效果。" : "此版本使用用户设置的内边距，并移除圆角、强制不透明以符合 Xcode 26 要求。")

        ## 使用方法

        ### 方法1：直接导入（推荐）
        1. 将整个图标集文件夹复制到你的 Xcode 项目中
        2. 在 `Assets.xcassets` 中右键选择 "New App Icon Set"
        3. 将生成的图标文件拖拽到对应的尺寸位置

        ### 方法2：手动配置
        1. 在 Xcode 中创建新的 App Icon Set
        2. 将对应的图标文件拖拽到正确的尺寸位置

        ## 图标尺寸说明

        ### macOS 图标
        - 16×16: 菜单栏、Dock 小图标
        - 32×32: 菜单栏、Dock 图标
        - 128×128: Finder 图标
        - 256×256: Finder 大图标
        - 512×512: 高分辨率显示器

        ### iOS 图标
        - 1024×1024: App Store 图标

        ## 注意事项

        - 所有图标都使用 PNG 格式，支持透明背景
        - 图标已根据设计规范优化，确保在不同尺寸下都清晰显示
        - \(selectedVersion == .version16 ? "内边距已自动调整以符合 Apple 设计规范" : "内边距保持用户自定义设置，圆角已移除，透明度强制为1以符合 Xcode 26 要求")
        - 如果需要在 Xcode 中调整图标，建议使用矢量工具重新生成

        ## 生成信息

        - 生成时间：\(Date().formatted())
        - 图标标题：\(iconProvider.currentData?.title ?? "N/A")
        - 背景样式：\(iconProvider.currentData?.backgroundId ?? "N/A")
        - 圆角设置：\(iconProvider.currentData?.cornerRadius ?? 0)
        - 缩放比例：\(iconProvider.currentData?.scale ?? 1.0)
        - 透明度：\(iconProvider.currentData?.opacity ?? 1.0)
        - 内边距：\(iconProvider.currentData?.padding ?? 0.0)（\(selectedVersion == .version16 ? "自动调整" : "用户设置")）

        ---
        由 GitOK 图标生成器创建
        """

        do {
            try readmeContent.write(to: saveTo, atomically: true, encoding: .utf8)
        } catch {
            MagicMessageProvider.shared.error("生成 README.md 失败：\(error)")
        }
    }
}

#Preview("App - Small Screen") {
    ContentLayout()
        .setInitialTab(IconPlugin.label)
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 600)
        .frame(height: 800)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .setInitialTab(IconPlugin.label)
        .hideTabPicker()
        .hideProjectActions()
        .hideSidebar()
        .inRootView()
        .frame(width: 800)
        .frame(height: 1000)
}
