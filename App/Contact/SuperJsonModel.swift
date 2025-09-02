import OSLog
import SwiftUI

protocol SuperJsonModel: Encodable, Identifiable, Equatable, Hashable {
    var path: String { get }
    var title: String { get }
}

extension SuperJsonModel {
    var id: String {
        path
    }
}

// MARK: 删除

extension SuperJsonModel {
    func delete() {
        do {
            try FileManager.default.removeItem(atPath: path)
        } catch let e {
            os_log(.error, "Error deleting item at path: \(path), error: \(e)")
        }
    }
}

// MARK: Store

extension SuperJsonModel {
    func save() throws {
        self.saveToFile(atPath: path)
    }

    // 将对象转换为 JSON 字符串
    func toJSONString() -> String? {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .sortedKeys
            let jsonData = try encoder.encode(self)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
        } catch {
            os_log(.error, "Error encoding BannerModel to JSON: \(error)")
        }
        return nil
    }

    // 保存 JSON 字符串到文件
    private func saveToFile(atPath path: String) {
        if let jsonString = self.toJSONString() {
            // 创建 FileManager 实例
            let fileManager = FileManager.default

            // 确保父文件夹存在，如果不存在则创建
            let directoryURL = URL(fileURLWithPath: path).deletingLastPathComponent()
            do {
                try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                os_log(.error, "Error creating directory: \(error)")
            }

            do {
                try jsonString.write(toFile: path, atomically: true, encoding: .utf8)
            } catch {
                os_log(.error, "Error saving JSON to file: \(error)")
            }
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
