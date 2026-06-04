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

    var classicData: ClassicBannerData? { b.banner.classicData }

    var body: some View {
        GroupBox("产品图片") {
            VStack(spacing: 12) {
                // 图片预览
                if let classicData = b.banner.classicData, classicData.imageId != nil {
                    AppSelectionTile(cornerRadius: 8, action: { showImagePicker = true }) {
                        classicData.getImage(b.banner.projectURL)
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
        }
        .onChange(of: classicData?.selectedDevice) {
            loadCurrentValues()
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
        do {
            try b.updateBanner { banner in
                var classicData = banner.classicData ?? ClassicBannerData()
                classicData = try classicData.changeImage(url, projectURL: banner.projectURL)
                banner.classicData = classicData
            }
            alert_success("图片更新成功")
        } catch {
            os_log(.error, "❌ 更新图片失败: \(error.localizedDescription)")
            alert_error("更新图片失败: \(error.localizedDescription)")
        }
    }

    private func updateSelectedDevice() {
        try? b.updateBanner { banner in
            var classicData = banner.classicData ?? ClassicBannerData()
            classicData.selectedDevice = selectedDevice
            banner.classicData = classicData
        }
    }
}
