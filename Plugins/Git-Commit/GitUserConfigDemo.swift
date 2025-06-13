import Foundation
import SwiftUI
import MagicCore
import OSLog

struct GitUserConfigDemo: View {
    @EnvironmentObject var data: DataProvider
    @State private var configs: [GitUserConfig] = []
    @State private var errorMessage: String?
    
    private var configRepo: any GitUserConfigRepoProtocol {
        data.repoManager.gitUserConfigRepo
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Git用户配置仓库演示")
                .font(.title2)
                .fontWeight(.bold)
            
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // 添加演示配置
            HStack {
                Button("添加演示配置") {
                    addDemoConfigs()
                }
                .buttonStyle(.borderedProminent)
                
                Button("清空所有配置") {
                    clearAllConfigs()
                }
                .buttonStyle(.bordered)
            }
            
            // 显示配置列表
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(configs) { config in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(config.name)
                                    .font(.headline)
                                Text(config.email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if config.isDefault {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                            }
                            
                            Button("设为默认") {
                                setAsDefault(config)
                            }
                            .buttonStyle(.borderless)
                            .disabled(config.isDefault)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            loadConfigs()
        }
    }
    
    private func addDemoConfigs() {
        do {
            // 添加一些演示配置
            let demoConfigs = [
                ("张三", "zhangsan@example.com"),
                ("李四", "lisi@company.com"),
                ("王五", "wangwu@github.com"),
                ("Developer", "dev@project.com")
            ]
            
            for (name, email) in demoConfigs {
                try configRepo.create(name: name, email: email, isDefault: false)
            }
            
            // 设置第一个为默认
            if let firstConfig = try configRepo.findAll(sortedBy: .ascending).first {
                try configRepo.setAsDefault(firstConfig)
            }
            
            loadConfigs()
            errorMessage = nil
            
        } catch {
            errorMessage = "添加演示配置失败: \(error.localizedDescription)"
        }
    }
    
    private func clearAllConfigs() {
        do {
            try configRepo.deleteAll()
            loadConfigs()
            errorMessage = nil
        } catch {
            errorMessage = "清空配置失败: \(error.localizedDescription)"
        }
    }
    
    private func setAsDefault(_ config: GitUserConfig) {
        do {
            try configRepo.setAsDefault(config)
            loadConfigs()
            errorMessage = nil
        } catch {
            errorMessage = "设置默认配置失败: \(error.localizedDescription)"
        }
    }
    
    private func loadConfigs() {
        do {
            configs = try configRepo.findAll(sortedBy: .descending)
        } catch {
            errorMessage = "加载配置失败: \(error.localizedDescription)"
        }
    }
}

#Preview {
    GitUserConfigDemo()
} 