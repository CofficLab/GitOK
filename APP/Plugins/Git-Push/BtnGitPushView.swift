import MagicAlert
import MagicKit
import OSLog
import SwiftUI

/// Git 同步按钮视图：根据当前分支状态提供 Fetch、Pull 或 Push 主操作。
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

    /// 视图主体：当存在项目且为 Git 仓库时显示同步按钮
    var body: some View {
        ZStack {
            if let project = vm.project, self.isGitProject {
                HStack(spacing: 0) {
                    Button {
                        perform(primaryAction, for: project)
                    } label: {
                        HStack(spacing: 6) {
                            actionIcon
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)

                            Text(primaryActionTitle)
                                .font(.caption)
                                .lineLimit(1)

                            if let badgeText = aheadBehindBadgeText {
                                Text(badgeText)
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 28)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Menu {
                        Button {
                            fetch(path: project.path, onComplete: {})
                        } label: {
                            Label("Fetch origin", systemImage: "arrow.clockwise")
                        }

                        Button {
                            pull(path: project.path, onComplete: {})
                        } label: {
                            Label("Pull origin", systemImage: "arrow.down")
                        }
                        .disabled(!vm.hasUpstream)

                        Button {
                            push(path: project.path, onComplete: {})
                        } label: {
                            Label(vm.hasUpstream ? "Push origin" : "Publish branch", systemImage: "arrow.up")
                        }
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.caption2.weight(.semibold))
                            .frame(width: 18, height: 28)
                    }
                    .menuStyle(.borderlessButton)
                    .menuIndicator(.hidden)
                    .fixedSize()
                }
                .padding(.leading, 10)
                .padding(.trailing, 6)
                .frame(width: 148, height: 36)
                .background(.quaternary.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                }
                .contentShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                .fixedSize(horizontal: true, vertical: false)
                .disabled(working)
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
    private enum RemotePrimaryAction {
        case fetch
        case pull
        case push
    }

    private var primaryAction: RemotePrimaryAction {
        if vm.hasUpstream, vm.behindCount > 0 {
            return .pull
        }

        if vm.hasUpstream, vm.aheadCount == 0 {
            return .fetch
        }

        return .push
    }

    private var actionIcon: Image {
        switch primaryAction {
        case .pull:
            return Image.download
        case .fetch:
            return Image(systemName: "arrow.clockwise")
        case .push:
            return Image.upload
        }
    }

    private var primaryActionTitle: String {
        switch primaryAction {
        case .pull:
            return "Pull origin"
        case .fetch:
            return "Fetch origin"
        case .push:
            return vm.hasUpstream ? "Push origin" : "Publish branch"
        }
    }

    private var aheadBehindBadgeText: String? {
        guard vm.hasUpstream else { return nil }

        if vm.aheadCount > 0, vm.behindCount > 0 {
            return "↑\(vm.aheadCount) ↓\(vm.behindCount)"
        }

        if vm.aheadCount > 0 {
            return "↑\(vm.aheadCount)"
        }

        if vm.behindCount > 0 {
            return "↓\(vm.behindCount)"
        }

        return nil
    }

    private var primaryActionHelp: String {
        if vm.hasUpstream, vm.behindCount > 0 {
            return "远程有 \(vm.behindCount) 个新提交，点击 Pull；菜单中仍可 Fetch 或 Push"
        }

        if vm.hasUpstream, vm.aheadCount == 0 {
            return "当前分支已同步，点击 Fetch 检查远程更新"
        }

        if vm.hasUpstream {
            return "本地有 \(vm.aheadCount) 个提交待推送"
        }

        return "当前分支还没有 upstream，点击 Publish branch 推送并建立跟踪关系"
    }

    private func perform(_ action: RemotePrimaryAction, for project: Project) {
        switch action {
        case .pull:
            pull(path: project.path, onComplete: {})
        case .fetch:
            fetch(path: project.path, onComplete: {})
        case .push:
            push(path: project.path, onComplete: {})
        }
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
