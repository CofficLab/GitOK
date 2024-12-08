import Foundation
import MagicKit
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
    ]

    init() {
        let verbose = false
        if verbose {
            os_log("\(Logger.initLog) PluginProvider")
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
