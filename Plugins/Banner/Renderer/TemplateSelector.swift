import SwiftUI

/**
 模板选择器组件
 横向滚动的卡片式模板选择器，直观展示各模板效果
 */
struct TemplateSelector: View {
    @EnvironmentObject var b: BannerProvider
    @State private var availableTemplates: [any BannerTemplateProtocol] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题
            HStack {
                Text("模板选择")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("共 \(availableTemplates.count) 个模板")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // 横向滚动的模板卡片
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(availableTemplates, id: \.id) { template in
                        TemplateCard(
                            template: template,
                            isSelected: b.selectedTemplate.id == template.id,
                            onSelect: {
                                b.setSelectedTemplate(template)
                            }
                        )
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .onAppear {
            loadTemplates()
        }
    }
    
    private func loadTemplates() {
        availableTemplates = BannerTemplateRepo.shared.getAllTemplates()
        if b.selectedTemplate.id.isEmpty {
            b.setSelectedTemplate(BannerTemplateRepo.shared.getDefaultTemplate())
        }
    }
}

/**
 模板卡片组件
 展示单个模板的预览和信息
 */
private struct TemplateCard: View {
    let template: any BannerTemplateProtocol
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // 模板示例预览
            template.createExampleView()
                .frame(width: 120, height: 80)
                .clipped()
            
            // 模板信息
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: template.systemImageName)
                        .font(.system(size: 12))
                        .foregroundColor(.accentColor)
                    
                    Text(template.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                
                Text(template.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(height: 32)
        }
        .frame(width: 120)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color(.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .onTapGesture {
            onSelect()
        }
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
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