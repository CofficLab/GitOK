import SwiftUI

/**
 模板选择器组件
 用于选择不同的Banner布局模板
 */
struct TemplateSelector: View {
    @Binding var selectedTemplate: any BannerTemplateProtocol
    @State private var availableTemplates: [any BannerTemplateProtocol] = []
    
    var body: some View {
        HStack(spacing: 16) {
            // 模板选择下拉菜单
            Picker("模板", selection: Binding(
                get: { selectedTemplate.id },
                set: { newId in
                    if let template = availableTemplates.first(where: { $0.id == newId }) {
                        selectedTemplate = template
                    }
                }
            )) {
                ForEach(availableTemplates, id: \.id) { template in
                    HStack {
                        Image(systemName: template.systemImageName)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(template.name)
                                .font(.body)
                            Text(template.description)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .tag(template.id)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .onAppear {
                loadTemplates()
            }

            Spacer()
        }
    }
    
    private func loadTemplates() {
        availableTemplates = BannerTemplateRepo.shared.getAllTemplates()
        if selectedTemplate.id.isEmpty {
            selectedTemplate = BannerTemplateRepo.shared.getDefaultTemplate()
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
    .frame(width: 800)
    .frame(height: 1000)
}
