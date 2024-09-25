import Foundation
import OSLog
import StoreKit
import SwiftData
import SwiftUI

class PluginProvider: ObservableObject, SuperLog, SuperThread {
    let emoji = "🧩"

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
            TileMerge()
            TileMessage()
        }
    }
}
