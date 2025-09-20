import MagicCore
import MagicAlert
import MagicUI
import OSLog
import SwiftUI

struct BtnCommitAndPush: View, SuperLog, SuperThread {
    @EnvironmentObject var g: DataProvider
    @EnvironmentObject var m: MagicMessageProvider

    static let emoji = "🐔"
    var commitMessage: String = ""
    var commitOnly: Bool = false

    var body: some View {
        MagicButton(
            icon: .iconUpload,
            title: commitOnly ? "Commit" : "Commit and Push",
            size: .auto,
            preventDoubleClick: true,
            loadingStyle: .spinner,
            action: { completion in
                guard let project = g.project else {
                    completion()
                    return
                }

                os_log("\(self.t)💼 Commit")

                DispatchQueue.main.async {
                    do {
                        try project.addAll()
                        
                        // 如果 commitMessage 为空，使用默认消息
                        let message = commitMessage.isEmpty ? "Auto commit" : commitMessage
                        try project.submit(message)
                        if commitOnly == false {
                            try project.push()
                        }

                        if commitOnly == false {
                            m.info("Commit and push success")
                        } else {
                            m.info("Commit success")
                        }
                    } catch {
                        m.error(error.localizedDescription)
                    }

                    completion()
                }
            }
        )
        .frame(height: 40)
        .frame(width: 150)
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideTabPicker()
            .hideProjectActions()
    }
    .frame(width: 600)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
