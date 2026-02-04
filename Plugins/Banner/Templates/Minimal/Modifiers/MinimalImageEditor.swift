import SwiftUI
import MagicAlert
import MagicKit
import MagicDevice
import UniformTypeIdentifiers

/**
 经典模板的图片编辑器
 专门为经典布局定制的图片编辑组件
 */
struct MinimalImageEditor: View {
    @EnvironmentObject var b: BannerProvider
    

    @State private var showImagePicker = false
    @State private var selectedDevice: MagicDevice? = nil

    var minimalData: MinimalBannerData? { b.banner.minimalData }

    var body: some View {
        GroupBox("产品图片") {
            VStack(spacing: 12) {
                // 图片预览
                if let minimalData = b.banner.minimalData, minimalData.imageId != nil {
                    minimalData.getImage(b.banner.project.url)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 100)
                        .cornerRadius(8)
                        .onTapGesture {
                            showImagePicker = true
                        }
                } else {
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
                        .onTapGesture {
                            showImagePicker = true
                        }
                }

                // 控制选项
                VStack(spacing: 8) {
                    // 更换图片按钮
                    Button("更换图片") {
                        showImagePicker = true
                    }
                    .frame(maxWidth: .infinity)

                    // 设备选择
                    HStack {
                        Text("设备边框")
                            .font(.body)

                        Spacer()

                        Picker("选择设备", selection: $selectedDevice) {
                            Text("无边框").tag(Optional<MagicDevice>.none)
//                            ForEach(MagicDevice.allCases, id: \.self) { device in
//                                Text(device.description).tag(Optional(device))
//                            }
                        }
                        .frame(width: 120)
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
        .onChange(of: minimalData?.selectedDevice) {
            loadCurrentValues()
        }
    }

    private func loadCurrentValues() {
        selectedDevice = minimalData?.selectedDevice
    }

    private func handleImageSelection(_ result: Result<[URL], Error>) {
        switch result {
        case let .success(urls):
            guard let url = urls.first else { return }
            changeImage(url)
        case let .failure(error):
            alert_error("选择图片失败: \(error.localizedDescription)")
        }
    }

    private func changeImage(_ url: URL) {
        do {
            try b.updateBanner { banner in
                var minimalData = banner.minimalData ?? MinimalBannerData()
                minimalData = try minimalData.changeImage(url, projectURL: banner.project.url)
                banner.minimalData = minimalData
            }
            alert_success("图片更新成功")
        } catch {
            alert_error("更新图片失败: \(error.localizedDescription)")
        }
    }

    private func updateSelectedDevice() {
        try? b.updateBanner { banner in
            var minimalData = banner.minimalData ?? MinimalBannerData()
            minimalData.selectedDevice = selectedDevice
            banner.minimalData = minimalData
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
