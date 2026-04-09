import SwiftUI

/// 已配置的项目分支列表区块
struct ConfiguredProjectsSectionView: View {
    @ObservedObject var settingsStore: AutoPushSettingsStore
    let isCurrentProject: (ProjectBranchAutoPushConfig) -> Bool
    let onToggle: (ProjectBranchAutoPushConfig) -> Void
    let onDelete: (ProjectBranchAutoPushConfig) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader
            
            if settingsStore.settings.isEmpty {
                emptyState
            } else {
                configList
            }
        }
    }
    
    // MARK: - Subviews
    
    private var sectionHeader: some View {
        HStack {
            Image(systemName: "list.bullet")
                .foregroundColor(.blue)
            Text("已配置的项目分支")
                .font(.headline)
            Spacer()
            
            if !settingsStore.settings.isEmpty {
                Text("\(settingsStore.settings.count) 个配置")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "cloudUpload")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("暂无配置")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("在当前项目中启用自动推送后，配置将显示在这里")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 150)
    }
    
    private var configList: some View {
        LazyVStack(spacing: 8) {
            ForEach(sortedConfigs) { config in
                ConfigRowView(
                    config: config,
                    isCurrentProject: isCurrentProject(config),
                    onToggle: onToggle,
                    onDelete: onDelete
                )
            }
        }
    }
    
    private var sortedConfigs: [ProjectBranchAutoPushConfig] {
        settingsStore.settings.values.sorted { $0.lastModified > $1.lastModified }
    }
}

#Preview("ConfiguredProjectsSectionView") {
    ConfiguredProjectsSectionView(
        settingsStore: AutoPushSettingsStore.shared,
        isCurrentProject: { _ in false },
        onToggle: { _ in },
        onDelete: { _ in }
    )
    .frame(width: 500, height: 300)
    .padding()
}