import SwiftUI
import MagicCore

/**
 * 远程图标视图组件
 * 负责显示从网络获取的图标，支持加载状态和错误处理
 * 数据流：RemoteIcon -> UI展示
 */
struct RemoteIconView: View {
    let remoteIcon: RemoteIcon
    let onTap: () -> Void
    
    @State private var image: Image = Image(systemName: "photo")
    @State private var isLoading: Bool = true
    @State private var hasError: Bool = false
    
    var body: some View {
        Group {
            if isLoading {
                // 加载状态
                ProgressView()
                    .frame(width: 40, height: 40)
            } else if hasError {
                // 错误状态
                Image(systemName: "exclamationmark.triangle")
                    .font(.title2)
                    .foregroundColor(.red)
                    .frame(width: 40, height: 40)
            } else {
                // 正常显示
                image
                    .resizable()
                    .frame(width: 40, height: 40)
            }
        }
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .onTapGesture {
            if !isLoading && !hasError {
                onTap()
            }
        }
        .onAppear {
            loadRemoteIcon()
        }
    }
    
    /// 加载远程图标
    private func loadRemoteIcon() {
        guard let iconURL = RemoteIconRepo().getIconURL(for: remoteIcon.path) else {
            print("RemoteIconView: 无法构建图标URL，路径: \(remoteIcon.path)")
            hasError = true
            isLoading = false
            return
        }
        
        print("RemoteIconView: 正在加载图标: \(iconURL)")
        
        // 异步加载图片
        Task {
            do {
                let (data, response) = try await URLSession.shared.data(from: iconURL)
                
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    print("RemoteIconView: HTTP错误，状态码: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                    await MainActor.run {
                        hasError = true
                        isLoading = false
                    }
                    return
                }
                
                print("RemoteIconView: 成功获取数据，大小: \(data.count) bytes")
                
                // 在主线程更新UI
                await MainActor.run {
                    // 检查文件类型
                    let fileExtension = remoteIcon.path.lowercased()
                    
                    if fileExtension.hasSuffix(".svg") {
                        // 对于SVG文件，尝试显示SVG内容，如果失败则显示占位符
                        print("RemoteIconView: SVG文件，尝试加载SVG内容")
                        // 尝试使用NSImage直接加载SVG
                        if let nsImage = NSImage(data: data) {
                            self.image = Image(nsImage: nsImage)
                            print("RemoteIconView: SVG加载成功")
                        } else {
                            // SVG加载失败，显示占位符
                            print("RemoteIconView: SVG加载失败，显示占位符")
                            self.image = Image(systemName: "doc.text")
                        }
                        self.isLoading = false
                    } else if let nsImage = NSImage(data: data) {
                        print("RemoteIconView: 成功创建NSImage")
                        self.image = Image(nsImage: nsImage)
                        self.isLoading = false
                    } else {
                        print("RemoteIconView: 无法从数据创建NSImage，数据大小: \(data.count)")
                        // 根据文件类型显示不同的占位符
                        if fileExtension.hasSuffix(".png") {
                            self.image = Image(systemName: "photo")
                        } else if fileExtension.hasSuffix(".jpg") || fileExtension.hasSuffix(".jpeg") {
                            self.image = Image(systemName: "camera")
                        } else if fileExtension.hasSuffix(".gif") {
                            self.image = Image(systemName: "play.circle")
                        } else if fileExtension.hasSuffix(".webp") {
                            self.image = Image(systemName: "globe")
                        } else {
                            self.image = Image(systemName: "doc")
                        }
                        self.isLoading = false
                        // 不设置为错误状态，而是显示占位符
                    }
                }
            } catch {
                print("RemoteIconView: 网络请求错误: \(error)")
                await MainActor.run {
                    hasError = true
                    isLoading = false
                }
            }
        }
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .setInitialTab("Icon")
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .setInitialTab("Icon")
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
