import MagicCore
import SwiftUI
import OSLog

/**
    标题编辑修改器
    以类似Backgrounds.swift的方式提供标题编辑功能。
    直接从BannerProvider获取和修改数据，实现自包含的组件设计。
    
    ## 功能特性
    - 文本编辑功能
    - 颜色选择功能
    - 实时预览效果
    - 自动保存更改
**/
struct TitleEditor: View {
    @EnvironmentObject var b: BannerProvider
    @EnvironmentObject var m: MagicMessageProvider
    
    @State private var isEditing = false
    @State private var editingText = ""
    
    /// Banner仓库实例
    private let bannerRepo = BannerRepo.shared
    
    /// 预定义的颜色选项
    private let colorOptions: [Color] = [
        .white, .black, .red, .green, .blue, .yellow, .orange, .purple
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            // 标题编辑区域
            GroupBox("标题编辑") {
                VStack(spacing: 12) {
                    if isEditing {
                        HStack {
                            TextField("请输入标题", text: $editingText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Button("完成") {
                                updateTitle(editingText)
                                isEditing = false
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Button("取消") {
                                isEditing = false
                                editingText = b.banner.title
                            }
                            .buttonStyle(.bordered)
                        }
                    } else {
                        HStack {
                            Text(b.banner.title.isEmpty ? "点击编辑标题" : b.banner.title)
                                .foregroundColor(b.banner.titleColor ?? .primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                            
                            Button("编辑") {
                                editingText = b.banner.title
                                isEditing = true
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
            
            // 颜色选择区域
            GroupBox("标题颜色") {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 40, maximum: 50), spacing: 8)
                ], spacing: 8) {
                    ForEach(colorOptions, id: \.self) { color in
                        makeColorOption(color)
                    }
                }
                .padding(8)
            }
        }
    }
    
    /**
        创建单个颜色选项
        
        ## 参数
        - `color`: 颜色选项
        
        ## 返回值
        返回可点击的颜色选项视图
    */
    func makeColorOption(_ color: Color) -> some View {
        let isSelected = b.banner.titleColor == color
        
        return Button(action: {
            updateTitleColor(color)
        }) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .stroke(Color.primary, lineWidth: 1)
                    )

                if isSelected {
                    Circle()
                        .stroke(Color.accentColor, lineWidth: 3)
                        .frame(width: 40, height: 40)
                        .shadow(color: .accentColor.opacity(0.3), radius: 4, x: 0, y: 0)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    /**
        更新Banner标题
        修改标题文本并自动保存到磁盘
        
        ## 参数
        - `newTitle`: 新的标题文本
    */
    private func updateTitle(_ newTitle: String) {
        guard b.banner != .empty else { 
            m.error("Banner为空，无法更新标题")
            return
        }
        
        var updatedBanner = b.banner
        updatedBanner.title = newTitle
        
        // 更新Provider中的状态
        b.setBanner(updatedBanner)
        
        // 保存到磁盘
        do {
            try bannerRepo.saveBanner(updatedBanner)
        } catch {
            m.error("保存标题失败：\(error.localizedDescription)")
        }
    }
    
    /**
        更新Banner标题颜色
        修改标题颜色并自动保存到磁盘
        
        ## 参数
        - `color`: 新的标题颜色
    */
    private func updateTitleColor(_ color: Color) {
        guard b.banner != .empty else { 
            m.error("Banner为空，无法更新标题颜色")
            return
        }
        
        var updatedBanner = b.banner
        updatedBanner.titleColor = color
        
        // 更新Provider中的状态
        b.setBanner(updatedBanner)
        
        // 保存到磁盘
        do {
            try bannerRepo.saveBanner(updatedBanner)
        } catch {
            m.error("保存标题颜色失败：\(error.localizedDescription)")
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
