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

                func setStatus(_ text: String?) {
                    Task { @MainActor in
                        g.activityStatus = text
                    }
                }

                Task.detached {
                    setStatus("添加文件中…")
                    do {
                        try project.addAll()

                        let message = commitMessage.isEmpty ? "Auto commit" : commitMessage

                        setStatus("提交中…")
                        try await MainActor.run {
                            try project.submit(message)
                        }

                        if commitOnly == false {
                            setStatus("推送中…")
                            try project.push()
                        }

                        await MainActor.run {
                            if commitOnly == false {
                                m.info("Commit and push success")
                            } else {
                                m.info("Commit success")
                            }
                        }
                    } catch {
                        await MainActor.run {
                            m.error(error.localizedDescription)
                        }
                    }

                    setStatus(nil)
                    await MainActor.run {
                        completion()
                    }
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
            .hideTabPicker()
            .hideProjectActions()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
