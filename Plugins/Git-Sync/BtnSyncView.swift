import MagicAlert
import MagicKit
import OSLog
import SwiftUI

/// 同步按钮视图组件，用于执行 git pull 和 push 操作
struct BtnSyncView: View, SuperLog, SuperEvent, SuperThread {
    /// emoji 标识符
    nonisolated static let emoji = "🔄"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    /// 环境对象：消息提供者
    

    /// 环境对象：数据提供者
    @EnvironmentObject var data: DataProvider

    /// 是否正在执行同步操作
    @State var working = false

    /// 旋转角度，用于加载动画
    @State var rotationAngle = 0.0

    /// 是否为Git项目
    @State var isGitProject = true

    /// 提交消息类别
    var commitMessage = CommitCategory.auto

    static let shared = BtnSyncView()

    private init() {}

    var body: some View {
        ZStack {
            if let project = data.project, self.isGitProject {
                Image.sync
                    .resizable()
                    .frame(height: 18)
                    .frame(width: 22)
                    .inButtonWithAction {
                        sync(path: project.path)
                    }
                    .help("和远程仓库同步")
                    .disabled(working)
                    .toolbarButtonStyle()
            } else {
                // 空状态占位符，确保视图始终有内容
                Color.clear.frame(width: 24, height: 24)
            }
        }
        .onAppear(perform: onAppear)
        .onChange(of: working) {
            let duration = 0.02
            if working {
                Timer.scheduledTimer(withTimeInterval: duration, repeats: true) { timer in
                    if !working {
                        timer.invalidate()
                        withAnimation(.easeInOut(duration: duration)) {
                            rotationAngle = 0.0
                        }
                    } else {
                        withAnimation(.easeInOut(duration: duration)) {
                            rotationAngle += 7
                        }
                    }
                }
            } else {
                withAnimation(.easeInOut(duration: 0.1)) {
                    rotationAngle = 0.0
                }
            }
        }
    }
}

extension BtnSyncView {
    func sync(path: String) {
        if Self.verbose {
            os_log("\(self.t)Starting sync for path: \(path)")
        }

        func setStatus(_ text: String?) {
            Task { @MainActor in
                data.activityStatus = text
            }
        }

        Task { @MainActor in
            withAnimation {
                working = true
            }
        }

        Task.detached {
            await setStatus("同步中…")
            do {
                // 检查是否有远程仓库
                if let project = await self.data.project {
                    let remotes = try project.remoteList()
                    if remotes.isEmpty {
                        if Self.verbose {
                            os_log("\(self.t)No remote repositories configured")
                        }
                        await MainActor.run {
                            MagicMessageProvider.shared.hideLoading()
                            self.reset()
                            alert_info("该项目还没有配置远程仓库，请先推送代码建立远程连接")
                        }
                        await setStatus(nil)
                        return
                    }
                }

                try await self.data.project?.sync()
                os_log("\(self.t)Sync completed successfully")
                await MainActor.run {
                    self.reset()
                }
            } catch let error {
                os_log(.error, "\(self.t)❌ Sync failed: \(error.localizedDescription)")
                await MainActor.run {
                    MagicMessageProvider.shared.hideLoading()
                    self.reset()
                    alert_error(error)
                }
            }
            await setStatus(nil)
        }
    }

    /// 显示错误提示
    /// - Parameter error: 错误对象
    func alert(error: Error) {
        self.main.async {
            alert_error(error.localizedDescription)
        }
    }
}

// MARK: - Action

extension BtnSyncView {
    /// 更新Git项目状态
    func updateIsGitProject() {
        self.isGitProject = data.project?.isGitRepo ?? false
    }

    /// 异步更新Git项目状态
    /// 使用异步方式避免阻塞主线程，解决CPU占用100%的问题
    func updateIsGitProjectAsync() async {
        let isGit = data.project?.isGitRepo ?? false
        await MainActor.run {
            self.isGitProject = isGit
        }
    }
}

// MARK: - Setter

extension BtnSyncView {
    /// 重置工作状态
    func reset() {
        withAnimation {
            self.working = false
        }
    }
}

// MARK: - Event Handler

extension BtnSyncView {
    /// 视图出现时的事件处理
    func onAppear() {
        Task {
            if Self.verbose {
                os_log("\(self.t)onAppear")
            }
            await self.updateIsGitProjectAsync()
        }
    }
}

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
