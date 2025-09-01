import MagicCore
import SwiftUI
import OSLog

/**
    功能特性编辑修改器
    以类似Backgrounds.swift的方式提供功能特性编辑功能。
    直接从BannerProvider获取和修改数据，实现自包含的组件设计。
    
    ## 功能特性
    - 添加/删除功能特性
    - 编辑功能特性文本
    - 拖拽排序支持
    - 自动保存更改
**/
struct FeaturesEditor: View {
    @EnvironmentObject var b: BannerProvider
    @EnvironmentObject var m: MagicMessageProvider
    
    @State private var editingIndex: Int? = nil
    @State private var editingText = ""
    
    /// Banner仓库实例
    private let bannerRepo = BannerRepo.shared
    
    var body: some View {
        VStack(spacing: 16) {
            // 标题和添加按钮
            HStack {
                Text("功能特性")
                    .font(.headline)
                
                Spacer()
                
                Button(action: addNewFeature) {
                    Label("添加特性", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            
            // 功能特性列表
            if b.banner.features.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "list.bullet")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    
                    Text("暂无功能特性")
                        .foregroundColor(.secondary)
                    
                    Text("点击上方按钮添加第一个功能特性")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(Array(b.banner.features.enumerated()), id: \.offset) { index, feature in
                            makeFeatureRow(index: index, feature: feature)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .frame(maxHeight: 200)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    /**
        创建单个功能特性行
        
        ## 参数
        - `index`: 功能特性索引
        - `feature`: 功能特性文本
        
        ## 返回值
        返回功能特性编辑行视图
    */
    func makeFeatureRow(index: Int, feature: String) -> some View {
        HStack(spacing: 12) {
            // 序号
            Text("\(index + 1)")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            // 编辑区域
            if editingIndex == index {
                TextField("输入功能特性", text: $editingText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("完成") {
                    updateFeature(at: index, with: editingText)
                    editingIndex = nil
                }
                .buttonStyle(.borderedProminent)
                
                Button("取消") {
                    editingIndex = nil
                    editingText = ""
                }
                .buttonStyle(.bordered)
            } else {
                Text(feature)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(8)
                    .onTapGesture {
                        editingText = feature
                        editingIndex = index
                    }
                
                Button("编辑") {
                    editingText = feature
                    editingIndex = index
                }
                .buttonStyle(.bordered)
                
                Button(action: {
                    deleteFeature(at: index)
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    /**
        添加新功能特性
    */
    private func addNewFeature() {
        guard b.banner != .empty else { 
            m.error("Banner为空，无法添加功能特性")
            return
        }
        
        var updatedBanner = b.banner
        updatedBanner.features.append("新功能特性")
        
        // 更新Provider中的状态
        b.setBanner(updatedBanner)
        
        // 保存到磁盘
        do {
            try bannerRepo.saveBanner(updatedBanner)
            
            // 自动编辑新添加的功能特性
            let newIndex = updatedBanner.features.count - 1
            editingText = "新功能特性"
            editingIndex = newIndex
        } catch {
            m.error("保存功能特性失败：\(error.localizedDescription)")
        }
    }
    
    /**
        更新功能特性
        
        ## 参数
        - `index`: 功能特性索引
        - `newText`: 新的功能特性文本
    */
    private func updateFeature(at index: Int, with newText: String) {
        guard b.banner != .empty, index < b.banner.features.count else { 
            m.error("无法更新功能特性")
            return
        }
        
        var updatedBanner = b.banner
        updatedBanner.features[index] = newText
        
        // 更新Provider中的状态
        b.setBanner(updatedBanner)
        
        // 保存到磁盘
        do {
            try bannerRepo.saveBanner(updatedBanner)
        } catch {
            m.error("保存功能特性失败：\(error.localizedDescription)")
        }
    }
    
    /**
        删除功能特性
        
        ## 参数
        - `index`: 要删除的功能特性索引
    */
    private func deleteFeature(at index: Int) {
        guard b.banner != .empty, index < b.banner.features.count else { 
            m.error("无法删除功能特性")
            return
        }
        
        var updatedBanner = b.banner
        updatedBanner.features.remove(at: index)
        
        // 更新Provider中的状态
        b.setBanner(updatedBanner)
        
        // 保存到磁盘
        do {
            try bannerRepo.saveBanner(updatedBanner)
            
            // 如果正在编辑被删除的项目，取消编辑状态
            if editingIndex == index {
                editingIndex = nil
                editingText = ""
            } else if let currentEditingIndex = editingIndex, currentEditingIndex > index {
                // 调整编辑索引
                editingIndex = currentEditingIndex - 1
            }
        } catch {
            m.error("删除功能特性失败：\(error.localizedDescription)")
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
