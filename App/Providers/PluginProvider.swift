import Foundation
import OSLog
import StoreKit
import SwiftData
import SwiftUI
import MagicKit

class PluginProvider: ObservableObject, SuperLog, SuperThread {
    let emoji = "🧩"
    let plugins: [SuperPlugin] = [
        BannerPlugin()
    ]

    init() {
        let verbose = false
        if verbose {
            os_log("\(Logger.initLog) PluginProvider")
        }
    }

    func getPlugins() -> some View {
        HStack(spacing: 0) {
            TileFile()
            TileProject()
            Spacer()
            TileQuickMerge()
            TileMerge()
            TileMessage()
        }
    }
}
