import MagicCore
import SwiftUI
import OSLog

/**
    副标题编辑修改器
    以类似Backgrounds.swift的方式提供副标题编辑功能。
    直接从BannerProvider获取和修改数据，实现自包含的组件设计。
    
    ## 功能特性
    - 文本编辑功能
    - 颜色选择功能
    - 实时预览效果
    - 自动保存更改
**/
struct SubTitleEditor: View {
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
            // 副标题编辑区域
            GroupBox("副标题编辑") {
                VStack(spacing: 12) {
                    if isEditing {
                        HStack {
                            TextField("请输入副标题", text: $editingText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Button("完成") {
                                updateSubTitle(editingText)
                                isEditing = false
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Button("取消") {
                                isEditing = false
                                editingText = b.banner.subTitle
                            }
                            .buttonStyle(.bordered)
                        }
                    } else {
                        HStack {
                            Text(b.banner.subTitle.isEmpty ? "点击编辑副标题" : b.banner.subTitle)
                                .foregroundColor(b.banner.subTitleColor ?? .primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                            
                            Button("编辑") {
                                editingText = b.banner.subTitle
                                isEditing = true
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
            
            // 颜色选择区域
            GroupBox("副标题颜色") {
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
        let isSelected = b.banner.subTitleColor == color
        
        return Button(action: {
            updateSubTitleColor(color)
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
        更新Banner副标题
        修改副标题文本并自动保存到磁盘
        
        ## 参数
        - `newSubTitle`: 新的副标题文本
    */
    private func updateSubTitle(_ newSubTitle: String) {
        guard b.banner != .empty else { 
            m.error("Banner为空，无法更新副标题")
            return
        }
        
        var updatedBanner = b.banner
        updatedBanner.subTitle = newSubTitle
        
        // 更新Provider中的状态
        b.setBanner(updatedBanner)
        
        // 保存到磁盘
        do {
            try bannerRepo.saveBanner(updatedBanner)
        } catch {
            m.error(error, title: "保存副标题失败")
        }
    }
    
    /**
        更新Banner副标题颜色
        修改副标题颜色并自动保存到磁盘
        
        ## 参数
        - `color`: 新的副标题颜色
    */
    private func updateSubTitleColor(_ color: Color) {
        guard b.banner != .empty else { 
            m.error("Banner为空，无法更新副标题颜色")
            return
        }
        
        var updatedBanner = b.banner
        updatedBanner.subTitleColor = color
        
        // 更新Provider中的状态
        b.setBanner(updatedBanner)
        
        // 保存到磁盘
        do {
            try bannerRepo.saveBanner(updatedBanner)
        } catch {
            m.error(error, title: "保存副标题颜色失败")
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
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .setInitialTab(BannerPlugin.label)
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
