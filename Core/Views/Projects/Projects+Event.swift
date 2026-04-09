import OSLog
import SwiftUI

// MARK: - Event

extension Projects {
    /// 视图出现时的事件处理
    func onAppear() {
        if Self.verbose {
            os_log("\(self.t)onAppear, projects.count = \(data.projects.count)")
            os_log("\(self.t)Current Project: \(data.project?.path ?? "")")
        }
        self.selection = data.project
    }
}
