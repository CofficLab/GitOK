import Foundation
import MagicCore
import OSLog
import StoreKit
import SwiftData
import SwiftUI

class PluginProvider: ObservableObject, SuperLog, SuperThread {
    let emoji = "🧩"
    let plugins: [SuperPlugin] = [
        GitPlugin(),
        BannerPlugin(),
        IconPlugin(),
        SmartFilePlugin(),
        SmartProjectPlugin(),
        QuickMergePlugin(),
        SmartMergePlugin(),
        SmartMessagePlugin(),
        OpenXcodePlugin(),
        OpenVSCodePlugin(),
        OpenCursorPlugin(),
        OpenTraePlugin(),
        OpenFinderPlugin(),
        OpenTerminalPlugin(),
        OpenRemotePlugin(),
        SyncPlugin(),
        BranchPlugin(),
        CommitPlugin()
    ]
    
    /// 获取所有标记为标签页的插件
    /// - Returns: 可作为标签页显示的插件数组
    var tabPlugins: [SuperPlugin] {
        plugins.filter { $0.isTab }
    }
    
    /// 检查是否所有插件的列表视图都为空
    /// - Parameter tab: 当前选中的标签页
    /// - Returns: 如果所有插件的addListView都返回nil则返回true，否则返回false
    func allListViewsEmpty(tab: String) -> Bool {
        var allEmpty = true
        for plugin in plugins {
            let listView = plugin.addListView(tab: tab)
            if listView != nil {
                os_log("插件 %@ 返回了非nil的列表视图", plugin.label)
                allEmpty = false
            }
        }
        return allEmpty
    }

    init() {
        let verbose = false
        if verbose {
            os_log("\(Self.onInit) PluginProvider")
        }

        var labelCounts: [String: Int] = [:]
        for plugin in plugins {
            labelCounts[plugin.label, default: 0] += 1
        }

        let duplicateLabels = labelCounts.filter { $0.value > 1 }.map { $0.key }
        if !duplicateLabels.isEmpty {
            assertionFailure("Duplicate labels: \(duplicateLabels)")
        }
    }
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    })
    .frame(width: 800, height: 800)
}

#Preview("App-Big Screen") {
    RootView {
        ContentView()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}

