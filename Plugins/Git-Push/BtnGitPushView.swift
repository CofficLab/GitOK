import MagicAlert
import MagicKit
import SwiftUI

/// Git 推送按钮视图：提供将本地提交推送到远程仓库的功能按钮。
struct BtnGitPushView: View, SuperLog, SuperThread {
    /// 日志标识符
    nonisolated static let emoji = "⬆️"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    /// 环境对象：消息提供者
    @EnvironmentObject var m: MagicMessageProvider

    /// 环境对象：数据提供者
    @EnvironmentObject var data: DataProvider

    /// 是否正在执行推送操作
    @State var working = false

    /// 是否为 Git 项目
    @State var isGitProject = false

    /// 单例实例
    static let shared = BtnGitPushView()

    private init() {}

    /// 视图主体：当存在项目且为Git仓库时显示推送按钮
    var body: some View {
        ZStack {
            if let project = data.project, self.isGitProject {
                Image.upload
                    .resizable()
                    .frame(height: 20)
                    .frame(width: 20)
                    .hoverScale(105)
                    .padding(.horizontal, 5)
                    .inButtonWithAction {
                        push(path: project.path, onComplete: {})
                    }
            } else {
                // 空状态占位符，确保视图始终有内容
                Color.clear.frame(width: 24, height: 24)
            }
        }
        .onAppear(perform: onAppear)
    }
}

// MARK: - Action

extension BtnGitPushView {
    /// 显示错误提示
    /// - Parameter error: 要显示的错误信息
    func alert(error: Error) {
        self.main.async {
            m.error(error)
        }
    }

    /// 重置工作状态
    func reset() {
        withAnimation {
            self.working = false
        }
    }

    /// 执行 Git 推送操作
    /// - Parameters:
    ///   - path: 项目路径
    ///   - onComplete: 完成回调
    func push(path: String, onComplete: @escaping () -> Void) {
        /// 设置状态信息
        /// - Parameter text: 状态文本，nil 表示清除状态
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
            await setStatus("推送中…")
            do {
                try await MainActor.run {
                    try self.data.project?.push()
                }
                await MainActor.run {
                    self.m.hideLoading()
                    self.reset()
                }
            } catch let error {
                await MainActor.run {
                    self.m.hideLoading()
                    self.reset()
                    self.m.error(error)
                }
            }
            await setStatus(nil)
            await MainActor.run {
                onComplete()
            }
        }
    }
}

// MARK: - Setter

extension BtnGitPushView {
    /// 更新 Git 项目状态：检查当前项目是否为 Git 仓库
    func updateIsGitProject() {
        self.isGitProject = data.project?.isGitRepo ?? false
    }

    /// 异步更新 Git 项目状态：使用异步方式避免阻塞主线程，解决 CPU 占用 100% 的问题
    func updateIsGitProjectAsync() async {
        let isGit = await data.project?.isGitAsync() ?? false
        await MainActor.run {
            self.isGitProject = isGit
        }
    }
}

// MARK: - Event Handler

extension BtnGitPushView {
    /// 视图出现时的事件处理
    func onAppear() {
        Task {
            await self.updateIsGitProjectAsync()
        }
    }
}

// MARK: - Preview

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
