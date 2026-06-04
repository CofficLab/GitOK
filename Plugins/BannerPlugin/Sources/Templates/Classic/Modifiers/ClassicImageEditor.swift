import AppKit
import SwiftUI
import GitOKCoreKit
import MagicAlert
import GitOKSupportKit
import OSLog
import UniformTypeIdentifiers

/**
 经典模板的图片编辑器
 专门为经典布局定制的图片编辑组件
 */
struct ClassicImageEditor: View {
    @EnvironmentObject var b: BannerProvider


    @State private var showImagePicker = false
    @State private var selectedDevice: MagicDevice? = nil
    @State private var previewImage: Image?

    var classicData: ClassicBannerData? { b.banner.classicData }

    var body: some View {
        GroupBox("产品图片") {
            VStack(spacing: 12) {
                // 图片预览
                if let classicData = b.banner.classicData, classicData.imageId != nil {
                    AppSelectionTile(cornerRadius: 8, action: { showImagePicker = true }) {
                        (previewImage ?? Image(ClassicBannerData.defaultImageId))
                            .resizable()
                            .scaledToFit()
                            .frame(height: 100)
                    }
                    .frame(height: 100)
                } else {
                    AppSelectionTile(cornerRadius: 8, action: { showImagePicker = true }) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 100)
                            .overlay(
                                VStack {
                                    Image(systemName: "photo")
                                        .font(.title)
                                    Text("点击选择图片")
                                        .font(.caption)
                                }
                                .foregroundColor(.secondary)
                            )
                    }
                    .frame(height: 100)
                }

                // 控制选项
                VStack(spacing: 8) {
                    // 更换图片按钮
                    AppButton(
                        "更换图片",
                        systemImage: "photo",
                        style: .secondary,
                        fillsWidth: true
                    ) {
                        showImagePicker = true
                    }

                    // 设备选择
                    HStack {
                        Text("设备边框")
                            .font(.body)

                        Spacer()

                        Picker("选择设备", selection: $selectedDevice) {
                            Text("无边框").tag(Optional<MagicDevice>.none)
                            ForEach(MagicDevice.allCases, id: \.self) { device in
                                Text(device.description).tag(Optional(device))
                            }
                        }
                        .frame(width: 240)
                        .onChange(of: selectedDevice) {
                            updateSelectedDevice()
                        }
                    }
                }
            }
            .padding(8)
        }
        .fileImporter(
            isPresented: $showImagePicker,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            handleImageSelection(result)
        }
        .onAppear {
            loadCurrentValues()
            loadPreviewImage()
        }
        .onChange(of: classicData?.selectedDevice) {
            loadCurrentValues()
        }
        .onChange(of: classicData?.imageId) {
            loadPreviewImage()
        }
        .onChange(of: b.banner.projectURL) {
            loadPreviewImage()
        }
    }

    private func loadCurrentValues() {
        selectedDevice = classicData?.selectedDevice
    }

    private func handleImageSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            changeImage(url)
        case .failure(let error):
            os_log(.error, "❌ 选择图片失败: \(error.localizedDescription)")
            alert_error("选择图片失败: \(error.localizedDescription)")
        }
    }

    private func changeImage(_ url: URL) {
        let projectURL = b.banner.projectURL

        Task.detached(priority: .userInitiated) {
            do {
                let imageId = try saveImportedImage(url, projectURL: projectURL)
                await MainActor.run {
                    do {
                        try b.updateBanner { banner in
                            var classicData = banner.classicData ?? ClassicBannerData()
                            classicData.imageId = imageId
                            banner.classicData = classicData
                        }
                        alert_success("图片更新成功")
                    } catch {
                        os_log(.error, "❌ 更新图片失败: \(error.localizedDescription)")
                        alert_error("更新图片失败: \(error.localizedDescription)")
                    }
                }
            } catch {
                await MainActor.run {
                    os_log(.error, "❌ 更新图片失败: \(error.localizedDescription)")
                    alert_error("更新图片失败: \(error.localizedDescription)")
                }
            }
        }
    }

    private func updateSelectedDevice() {
        try? b.updateBanner { banner in
            var classicData = banner.classicData ?? ClassicBannerData()
            classicData.selectedDevice = selectedDevice
            banner.classicData = classicData
        }
    }

    private func loadPreviewImage() {
        guard let imageId = classicData?.imageId else {
            previewImage = nil
            return
        }

        let projectURL = b.banner.projectURL
        let cleanPath = imageId.replacingOccurrences(of: "\\/", with: "/")
        let imageURL = URL(fileURLWithPath: projectURL.path).appendingPathComponent(cleanPath)

        Task.detached(priority: .userInitiated) {
            let data = try? Data(contentsOf: imageURL)
            await MainActor.run {
                guard classicData?.imageId == imageId, b.banner.projectURL == projectURL else { return }
                if let data, let nsImage = NSImage(data: data) {
                    previewImage = Image(nsImage: nsImage)
                } else {
                    previewImage = nil
                }
            }
        }
    }

    private nonisolated func saveImportedImage(_ url: URL, projectURL: URL) throws -> String {
        let ext = url.pathExtension
        let bannerRootURL = projectURL.appendingPathComponent(BannerRepo.bannerStoragePath)
        let imagesFolder = bannerRootURL.appendingPathComponent("images")
        let storeURL = imagesFolder.appendingPathComponent("\(Date.nowCompact).\(ext)")
        try FileManager.default.createDirectory(at: imagesFolder, withIntermediateDirectories: true)
        try FileManager.default.copyItem(at: url, to: storeURL)
        return storeURL.relativePath.replacingOccurrences(of: projectURL.path, with: "")
    }
}
