import MagicCore
import OSLog
import SwiftUI

/**
     图片编辑修改器
     以类似Backgrounds.swift的方式提供图片编辑功能。
     直接从BannerProvider获取和修改数据，实现自包含的组件设计。

     ## 功能特性
     - 图片选择和更换
     - 显示模式切换（在屏幕内/外）
     - 实时预览效果
     - 自动保存更改
 **/
struct ImageEditor: View {
    @EnvironmentObject var b: BannerProvider
    @EnvironmentObject var m: MagicMessageProvider

    /// Banner仓库实例
    private let bannerRepo = BannerRepo.shared

    var body: some View {
        VStack(spacing: 16) {
            // 图片预览和基本信息
            GroupBox("图片设置") {
                HStack(spacing: 12) {
                    // 图片预览
                    HStack {
                        if let imageId = b.banner.imageId {
                            AsyncImage(url: URL(string: imageId)) { image in
                                image
                                    .resizable()
                                    .scaledToFit()
                            } placeholder: {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay(
                                        Text("加载中...")
                                            .foregroundColor(.secondary)
                                    )
                            }
                            .frame(width: 100, height: 100)
                            .cornerRadius(8)
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 100, height: 100)
                                .cornerRadius(8)
                                .overlay(
                                    VStack {
                                        Image(systemName: "photo")
                                            .font(.largeTitle)
                                            .foregroundColor(.secondary)
                                        Text("无图片")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                )
                        }

                        Spacer()
                    }

                    // 操作按钮
                    VStack {
                        HStack(spacing: 12) {
                            Button("选择图片") {
                                selectImage()
                            }
                            .buttonStyle(.borderedProminent)

                            if b.banner.imageId?.isEmpty == false {
                                Button("移除图片") {
                                    removeImage()
                                }
                                .buttonStyle(.bordered)
                            }

                            Spacer()
                        }
                        
                        Spacer()

                        HStack {
                            Toggle("在屏幕内显示", isOn: Binding(
                                get: { b.banner.inScreen },
                                set: { newValue in
                                    updateScreenMode(newValue)
                                }
                            ))
                            .toggleStyle(SwitchToggleStyle())
                            Spacer()
                        }
                    }
                }
            }
        }
    }

    /**
         选择图片
         打开文件选择器让用户选择图片文件
     */
    private func selectImage() {
        guard b.banner != .empty else {
            m.error("Banner为空，无法选择图片")
            return
        }

        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.image]
        panel.title = "选择图片"
        panel.message = "请选择要添加到Banner的图片文件"

        if panel.runModal() == .OK, let url = panel.url {
            do {
                var updatedBanner = b.banner
                try updatedBanner.changeImage(url)

                // 更新Provider中的状态
                b.setBanner(updatedBanner)

                // 保存到磁盘
                try bannerRepo.saveBanner(updatedBanner)

                m.success("图片更新成功")
            } catch {
                m.error("更新图片失败：\(error.localizedDescription)")
            }
        }
    }

    /**
         移除图片
         清除当前设置的图片
     */
    private func removeImage() {
        guard b.banner != .empty else {
            m.error("Banner为空，无法移除图片")
            return
        }

        var updatedBanner = b.banner
        updatedBanner.imageId = nil

        // 更新Provider中的状态
        b.setBanner(updatedBanner)

        // 保存到磁盘
        do {
            try bannerRepo.saveBanner(updatedBanner)
            m.success("图片已移除")
        } catch {
            m.error("移除图片失败：\(error.localizedDescription)")
        }
    }

    /**
         更新屏幕显示模式

         ## 参数
         - `inScreen`: 是否在屏幕内显示
     */
    private func updateScreenMode(_ inScreen: Bool) {
        guard b.banner != .empty else {
            m.error("Banner为空，无法更新显示模式")
            return
        }

        var updatedBanner = b.banner
        updatedBanner.inScreen = inScreen

        // 更新Provider中的状态
        b.setBanner(updatedBanner)

        // 保存到磁盘
        do {
            try bannerRepo.saveBanner(updatedBanner)
        } catch {
            m.error("保存显示模式失败：\(error.localizedDescription)")
        }
    }
}

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .hideTabPicker()
        .inRootView()
        .frame(width: 800)
        .frame(height: 1000)
}
