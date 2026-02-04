import MagicAlert
import MagicKit
import SwiftUI

/// Git 拉取按钮视图：提供从远程仓库拉取最新代码的功能按钮。
struct BtnGitPullView: View, SuperLog, SuperEvent, SuperThread {
    /// 日志标识符
    nonisolated static let emoji = "⬇️"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    /// 环境对象：消息提供者
    @EnvironmentObject var m: MagicMessageProvider

    /// 环境对象：数据提供者
    @EnvironmentObject var data: DataProvider

    /// 是否正在执行拉取操作
    @State var working = false

    /// 是否为 Git 项目
    @State var isGitProject = false

    /// 单例实例
    static let shared = BtnGitPullView()

    private init() {}

    var body: some View {
        ZStack {
            if let project = data.project, self.isGitProject {
                Image.download
                    .resizable()
                    .frame(height: 18)
                    .frame(width: 18)
                    .inButtonWithAction {
                        pull(path: project.path, onComplete: {})
                    }
                    .disabled(working)
                    .toolbarButtonStyle()
            } else {
                // 空状态占位符，确保视图始终有内容
                Color.clear.frame(width: 24, height: 24)
            }
        }
        .onAppear(perform: onAppear)
    }
}

// MARK: - View

extension BtnGitPullView {
    // View 相关的辅助视图和修饰符可以在这里添加
}

// MARK: - Action

extension BtnGitPullView {
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

    /// 执行 Git 拉取操作
    /// - Parameters:
    ///   - path: 项目路径
    ///   - onComplete: 完成回调
    func pull(path: String, onComplete: @escaping () -> Void) {
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
            await setStatus("拉取中…")
            do {
                try await self.data.project?.pull()
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

extension BtnGitPullView {
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

extension BtnGitPullView {
    /// 视图出现时的事件处理
    func onAppear() {
        Task {
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
        .hideTabPicker()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
