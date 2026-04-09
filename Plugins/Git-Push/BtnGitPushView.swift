import MagicAlert
import MagicKit
import OSLog
import SwiftUI

/// Git 推送按钮视图：提供将本地提交推送到远程仓库的功能按钮。
struct BtnGitPushView: View, SuperLog, SuperThread {
    /// 日志标识符
    nonisolated static let emoji = "⬆️"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    /// 环境对象：消息提供者
    

    /// 环境对象：数据提供者
    @EnvironmentObject var data: DataVM
    @EnvironmentObject var vm: ProjectVM

    /// 是否正在执行推送操作
    @State var working = false

    /// 是否为 Git 项目
    @State var isGitProject = false

    /// 单例实例
    static let shared = BtnGitPushView()

    private init() {}

    /// 视图主体：当存在项目且为 Git 仓库时显示推送按钮
    var body: some View {
        ZStack {
            if let project = vm.project, self.isGitProject {
                Image.upload
                    .resizable()
                    .frame(height: 18)
                    .frame(width: 18)
                    .inButtonWithAction {
                        push(path: project.path, onComplete: {})
                    }
                    .toolbarButtonStyle()
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
            os_log(.error, "\(Self.t)❌ 推送错误: \(error.localizedDescription)")
            alert_error(error)
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

        // ✅ 修复：在后台线程执行 Git 操作，避免阻塞主线程
        Task.detached {
            await setStatus("推送中…")
            
            do {
                // ✅ 关键修复：push() 是阻塞操作，必须在后台线程执行，不能在 MainActor.run 中
                try self.vm.project?.push()
                
                await MainActor.run {
                    MagicMessageProvider.shared.hideLoading()
                    self.reset()
                }
            } catch let error {
                await MainActor.run {
                    os_log(.error, "\(Self.t)❌ Git 推送失败: \(error.localizedDescription)")
                    MagicMessageProvider.shared.hideLoading()
                    self.reset()
                    alert_error(error)
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
        self.isGitProject = vm.project?.isGitRepo ?? false
    }

    /// 异步更新 Git 项目状态：使用异步方式避免阻塞主线程，解决 CPU 占用 100% 的问题
    func updateIsGitProjectAsync() async {
        let isGit = await vm.project?.isGit() ?? false
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
