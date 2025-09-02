import Foundation
import MagicCore
import OSLog
import StoreKit
import SwiftData
import SwiftUI

class PluginProvider: ObservableObject, SuperLog, SuperThread {
    let emoji = "🧩"
    let plugins: [SuperPlugin]
    
    /// 获取所有标记为标签页的插件
    /// - Returns: 可作为标签页显示的插件数组
    var tabPlugins: [SuperPlugin] {
        plugins.filter { $0.isTab }
    }
    
    /// 检查是否所有插件的列表视图都为空
    /// - Parameter 
    ///      - tab: 当前选中的标签页
    ///     - project: 当前选中的项目
    /// - Returns: 如果所有插件的addListView都返回nil则返回true，否则返回false
    func allListViewsEmpty(tab: String, project: Project?) -> Bool {
        var allEmpty = true
        for plugin in plugins {
            let listView = plugin.addListView(tab: tab, project: project)
            if listView != nil {
                allEmpty = false
            }
        }
        return allEmpty
    }

    init(plugins: [SuperPlugin]) {
        let verbose = false
        if verbose {
            os_log("\(Self.onInit) PluginProvider")
        }
        
        self.plugins = plugins

        var labelCounts: [String: Int] = [:]
        for plugin in plugins {
            labelCounts[plugin.instanceLabel, default: 0] += 1
        }

        let duplicateLabels = labelCounts.filter { $0.value > 1 }.map { $0.key }
        if !duplicateLabels.isEmpty {
            assertionFailure("Duplicate labels: \(duplicateLabels)")
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
