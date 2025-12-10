import MagicCore
import MagicAlert
import MagicUI
import SwiftUI

struct BtnSyncView: View, SuperLog, SuperEvent, SuperThread {
    @EnvironmentObject var m: MagicMessageProvider
    @EnvironmentObject var data: DataProvider

    @State var working = false
    @State var rotationAngle = 0.0
    @State var isGitProject = false

    var commitMessage = CommitCategory.auto

    static let shared = BtnSyncView()

    private init() {}

    var body: some View {
        ZStack {
            if let project = data.project, self.isGitProject {
                MagicButton(icon: .iconSync) { completion in
                    sync(path: project.path)
                    completion()
                }
                .magicShape(.circle)
                .magicStyle(.secondary)
                .magicShapeVisibility(.onHover)
                .help("和远程仓库同步")
                .disabled(working)
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
            } else {
                // 空状态占位符，确保视图始终有内容
                Color.clear.frame(width: 24, height: 24)
            }
        }
        .onAppear(perform: onAppear)
    }

    func sync(path: String) {
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
            setStatus("同步中…")
            do {
                try await self.data.project?.sync()
                await MainActor.run {
                    self.reset()
                }
            } catch let error {
                await MainActor.run {
                    self.m.hideLoading()
                    self.reset()
                    self.m.error(error.localizedDescription)
                }
            }
            setStatus(nil)
        }
    }

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
}

// MARK: - Action

extension BtnSyncView {
    func updateIsGitProject() {
        self.isGitProject = data.project?.isGit() ?? false
    }
    
    /**
        异步更新Git项目状态
        
        使用异步方式避免阻塞主线程，解决CPU占用100%的问题
     */
    func updateIsGitProjectAsync() async {
        let isGit = data.project?.isGit() ?? false
        await MainActor.run {
            self.isGitProject = isGit
        }
    }
}

// MARK: - Event

extension BtnSyncView {
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
//            .hideProjectActions()
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
