import Foundation
import GitOKCoreKit

import SwiftUI

/**
 * 项目图标仓库
 * 负责从项目目录扫描和获取所有的IconData
 */
class ProjectIconRepo {
    /// 图标存储目录路径（相对于项目根目录）
    static let iconStoragePath = ".gitok/icons"

    /// 从项目目录获取所有图标模型
    /// - Parameter projectURL: 项目根目录
    /// - Returns: 该project下的所有IconData数组
    static func getIconData(from projectURL: URL) -> [IconData] {
        let iconDirectoryURL = projectURL.appendingPathComponent(ProjectIconRepo.iconStoragePath)

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

    static func getIconDataAsync(from projectURL: URL) async -> [IconData] {
        await Task.detached(priority: .userInitiated) {
            getIconData(from: projectURL)
        }.value
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
