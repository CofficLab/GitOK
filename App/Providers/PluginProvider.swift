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

