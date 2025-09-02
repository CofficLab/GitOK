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
                if b.banner.imageId != nil {
                    b.banner.getImage()
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
        inScreen = b.banner.inScreen
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
                try banner.changeImage(url)
            }
            m.success("图片更新成功")
        } catch {
            m.error("更新图片失败: \(error.localizedDescription)")
        }
    }
    
    private func updateInScreen() {
        try? b.updateBanner { banner in
            banner.inScreen = inScreen
        }
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .setInitialTab(BannerPlugin.label)
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 600)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .setInitialTab(BannerPlugin.label)
            .hideSidebar()
    }
    .frame(width: 800)
    .frame(height: 1000)
}
