import SwiftUI
import MagicCore
import UniformTypeIdentifiers

/**
 简约模板的图片编辑器
 专门为简约布局定制的图片编辑组件，支持圆形裁剪
 */
struct MinimalImageEditor: View {
    @EnvironmentObject var b: BannerProvider
    @EnvironmentObject var m: MagicMessageProvider
    
    @State private var showImagePicker = false
    @State private var isCircular = true
    @State private var imageSize: Double = 200.0
    
    var body: some View {
        GroupBox("图片设置") {
            VStack(spacing: 12) {
                // 图片预览
                if b.banner.imageId != nil {
                    let image = b.banner.getImage()
                    Group {
                        if isCircular {
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                        } else {
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(height: 80)
                                .cornerRadius(8)
                        }
                    }
                    .onTapGesture {
                        showImagePicker = true
                    }
                } else {
                    Group {
                        if isCircular {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 80, height: 80)
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 80)
                        }
                    }
                    .overlay(
                        VStack {
                            Image(systemName: "photo")
                                .font(.title2)
                            Text("选择图片")
                                .font(.caption2)
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
                    
                    // 圆形显示开关
                    HStack {
                        Text("圆形显示")
                            .font(.body)
                        
                        Spacer()
                        
                        Toggle("", isOn: $isCircular)
                            .onChange(of: isCircular) {
                                updateImageStyle()
                            }
                    }
                    
                    // 图片大小调节
                    HStack {
                        Text("图片大小")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Slider(
                            value: $imageSize,
                            in: 100.0...400.0,
                            step: 10.0
                        )
                        .onChange(of: imageSize) {
                            updateImageSize()
                        }
                        
                        Text("\(Int(imageSize))px")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 50, alignment: .trailing)
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
        // 加载简约模板特有的图片设置
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
            var updatedBanner = b.banner
            try updatedBanner.changeImage(url)
            b.banner = updatedBanner
            m.success("图片更新成功")
        } catch {
            m.error("更新图片失败: \(error.localizedDescription)")
        }
    }
    
    private func updateImageStyle() {
        // 简约模板特有的图片样式更新逻辑
    }
    
    private func updateImageSize() {
        // 简约模板特有的图片大小更新逻辑
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
    }
    .frame(width: 800)
    .frame(height: 1000)
}
