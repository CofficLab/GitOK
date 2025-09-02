import SwiftUI
import MagicCore
import UniformTypeIdentifiers

/**
 经典模板的图片编辑器
 专门为经典布局定制的图片编辑组件
 */
struct MinimalImageEditor: View {
    @EnvironmentObject var b: BannerProvider
    @EnvironmentObject var m: MagicMessageProvider
    
    @State private var showImagePicker = false
    @State private var inScreen = false
    
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
                    
                    // 屏幕显示开关
                    HStack {
                        Text("显示设备边框")
                            .font(.body)
                        
                        Spacer()
                        
                        Toggle("", isOn: $inScreen)
                            .onChange(of: inScreen) {
                                updateInScreen()
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
    }
    
    private func loadCurrentValues() {
        if let minimalData = b.banner.minimalData {
            inScreen = minimalData.inScreen
        }
    }
    
    private func handleImageSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            changeImage(url)
        case .failure(let error):
            m.error("选择图片失败: \(error.localizedDescription)")
        }
    }
    
    private func changeImage(_ url: URL) {
        do {
            try b.updateBanner { banner in
                var minimalData = banner.minimalData ?? MinimalBannerData()
                minimalData = try minimalData.changeImage(url, projectURL: banner.project.url)
                banner.minimalData = minimalData
            }
            m.success("图片更新成功")
        } catch {
            m.error("更新图片失败: \(error.localizedDescription)")
        }
    }
    
    private func updateInScreen() {
        try? b.updateBanner { banner in
            var minimalData = banner.minimalData ?? MinimalBannerData()
            minimalData.inScreen = inScreen
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
