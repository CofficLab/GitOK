import Foundation

import SwiftUI

/**
 * 项目图标仓库
 * 负责从项目目录扫描和获取所有的IconData
 */
class ProjectIconRepo {
    /// 图标存储目录路径（相对于项目根目录）
    static let iconStoragePath = ".gitok/icons"

    /// 从Project对象获取所有图标模型
    /// - Parameter project: Project对象
    /// - Returns: 该project下的所有IconData数组
    static func getIconData(from project: Project) -> [IconData] {
        let projectRootURL = URL(fileURLWithPath: project.path)
        let iconDirectoryURL = projectRootURL.appendingPathComponent(ProjectIconRepo.iconStoragePath)
        
        var models: [IconData] = []
        
        do {
            // 检查图标目录是否存在
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: iconDirectoryURL.path, isDirectory: &isDirectory),
                  isDirectory.boolValue else {
                return []
            }
            
            // 扫描图标目录中的所有JSON文件
            let files = try FileManager.default.contentsOfDirectory(atPath: iconDirectoryURL.path)
            for file in files {
                if file.hasSuffix(".json") {
                    let fileURL = iconDirectoryURL.appendingPathComponent(file)
                    if let model = tryLoadIconData(from: fileURL) {
                        models.append(model)
                    }
                }
            }
        } catch {
            return []
        }
        
        // 按标题排序，保持稳定的顺序
        return models.sorted { $0.title < $1.title }
    }
    
    /// 尝试加载图标模型
    /// - Parameter fileURL: 图标配置文件URL
    /// - Returns: 图标模型，如果加载失败则返回nil
    private static func tryLoadIconData(from fileURL: URL) -> IconData? {
        do {
            let model = try IconData.fromJSONFile(fileURL)
            return model
        } catch {
            // 不是有效的图标配置文件，忽略
            return nil
        }
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideProjectActions()
            .hideSidebar()
            .hideTabPicker()
            .setInitialTab(IconPlugin.label)
    }
    .frame(width: 800)
    .frame(height: 800)
}

#Preview("App-Big Screen") {
    RootView {
        ContentLayout()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
