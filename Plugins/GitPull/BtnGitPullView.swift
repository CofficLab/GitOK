import MagicAlert
import MagicCore
import MagicUI
import SwiftUI

struct BtnGitPullView: View, SuperLog, SuperEvent, SuperThread {
    @EnvironmentObject var m: MagicMessageProvider
    @EnvironmentObject var data: DataProvider

    @State var working = false
    @State var isGitProject = false

    static let shared = BtnGitPullView()

    private init() {}

    var body: some View {
        ZStack {
            if let project = data.project, self.isGitProject {
                MagicButton(icon: .iconDownload) { completion in
                    pull(path: project.path, onComplete: completion)
                }
                .magicShape(.circle)
                .magicStyle(.secondary)
                .magicShapeVisibility(.onHover)
                .help("从远程仓库拉取最新代码")
                .disabled(working)
            } else {
                // 空状态占位符，确保视图始终有内容
                Color.clear.frame(width: 24, height: 24)
            }
        }
        .onAppear(perform: onAppear)
    }
}

// MARK: - Action

extension BtnGitPullView {
    func alert(error: Error) {
        self.main.async {
            m.error(error.localizedDescription)
        }
    }

    func reset() {
        withAnimation {
            self.working = false
        }
    }

    func updateIsGitProject() {
        self.isGitProject = data.project?.isGit() ?? false
    }

    /**
        异步更新Git项目状态

        使用异步方式避免阻塞主线程，解决CPU占用100%的问题
     */
    func updateIsGitProjectAsync() async {
        let isGit = await data.project?.isGitAsync() ?? false
        await MainActor.run {
            self.isGitProject = isGit
        }
    }

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
            setStatus("拉取中…")
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
                    self.m.error("拉取失败: \(error.localizedDescription)")
                }
            }
            setStatus(nil)
            await MainActor.run {
                onComplete()
            }
        }
    }
}

// MARK: - Event

extension BtnGitPullView {
    func onAppear() {
        Task {
            await self.updateIsGitProjectAsync()
        }
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideTabPicker()
    }
    .frame(width: 800)
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
