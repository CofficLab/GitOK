import Foundation
import OSLog
import SwiftData
import SwiftUI

actor DB: ModelActor {
    static let label = "📦 DB::"
    
    let modelContainer: ModelContainer
    let modelExecutor: any ModelExecutor

    var fileManager = FileManager.default
    var queue = DispatchQueue(label: "DB")
    var context: ModelContext
    var label: String = DB.label

    init(_ container: ModelContainer) {
        os_log("\(Logger.isMain)🚩 初始化 DB")

        self.modelContainer = container
        self.context = ModelContext(container)
        self.context.autosaveEnabled = false
        self.modelExecutor = DefaultSerialModelExecutor(
            modelContext: context
        )
    }
    
    func hasChanges() -> Bool {
        context.hasChanges
    }

    func save() {
        do {
            try self.context.save()
        } catch let e {
            print(e)
        }
    }
}

#Preview {
    AppPreview()
}
