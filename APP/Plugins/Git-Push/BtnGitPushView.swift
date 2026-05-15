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

    /// Push 被远程拒绝且需要先获取远程更新
    @State private var showPushNeedsFetchAlert = false

    /// 单例实例
    static let shared = BtnGitPushView()

    private init() {}

    /// 视图主体：当存在项目且为 Git 仓库时显示推送按钮
    var body: some View {
        ZStack {
            if let project = vm.project, self.isGitProject {
                actionIcon
                    .resizable()
                    .frame(height: 18)
                    .frame(width: 18)
                    .inButtonWithAction {
                        performPrimaryAction(for: project)
                    }
                    .disabled(working)
                    .toolbarButtonStyle()
                    .help(primaryActionHelp)
            } else {
                // 空状态占位符，确保视图始终有内容
                Color.clear.frame(width: 24, height: 24)
            }
        }
        .onAppear(perform: onAppear)
        .alert("远程有新的提交", isPresented: $showPushNeedsFetchAlert) {
            Button("Fetch") {
                guard let project = vm.project else { return }
                fetch(path: project.path, onComplete: {})
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("当前分支无法推送，因为远程分支包含本地还没有的提交。请先 Fetch，再选择 Pull 或 Rebase 后重新 Push。")
        }
    }
}

// MARK: - Action

extension BtnGitPushView {
    private var actionIcon: Image {
        if vm.hasUpstream, vm.behindCount > 0 {
            return Image.download
        }

        if vm.hasUpstream, vm.aheadCount == 0 {
            return Image(systemName: "arrow.clockwise")
        }

        return Image.upload
    }

    private var primaryActionHelp: String {
        if vm.hasUpstream, vm.behindCount > 0 {
            return "远程有 \(vm.behindCount) 个新提交，先拉取"
        }

        if vm.hasUpstream, vm.aheadCount == 0 {
            return "获取远程更新"
        }

        return "推送本地提交"
    }

    private func performPrimaryAction(for project: Project) {
        if vm.hasUpstream, vm.behindCount > 0 {
            pull(path: project.path, onComplete: {})
            return
        }

        if vm.hasUpstream, vm.aheadCount == 0 {
            fetch(path: project.path, onComplete: {})
            return
        }

        push(path: project.path, onComplete: {})
    }

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
        let project = vm.project

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
                try project?.push()
                
                await MainActor.run {
                    MagicMessageProvider.shared.hideLoading()
                    self.reset()
                }
            } catch let error {
                await MainActor.run {
                    os_log(.error, "\(Self.t)❌ Git 推送失败: \(error.localizedDescription)")
                    MagicMessageProvider.shared.hideLoading()
                    self.reset()
                    if case GitOperationError.pushNeedsFetch = error {
                        showPushNeedsFetchAlert = true
                    } else {
                        alert_error(error)
                    }
                }
            }
            
            await setStatus(nil)
            await MainActor.run {
                onComplete()
            }
        }
    }

    func pull(path: String, onComplete: @escaping () -> Void) {
        let project = vm.project

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
                try project?.pull()
                await MainActor.run {
                    MagicMessageProvider.shared.hideLoading()
                    self.reset()
                }
            } catch let error {
                await MainActor.run {
                    os_log(.error, "\(Self.t)❌ Git 拉取失败: \(error.localizedDescription)")
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

    func fetch(path: String, onComplete: @escaping () -> Void) {
        let project = vm.project

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
            await setStatus("获取远程更新中…")
            do {
                try project?.fetch()
                await MainActor.run {
                    MagicMessageProvider.shared.hideLoading()
                    self.reset()
                }
            } catch let error {
                await MainActor.run {
                    os_log(.error, "\(Self.t)❌ Git Fetch 失败: \(error.localizedDescription)")
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
        let isGit = vm.project?.isGit() ?? false
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
