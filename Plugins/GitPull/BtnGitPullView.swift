import MagicCore
import SwiftUI

struct BtnGitPullView: View, SuperLog, SuperEvent, SuperThread {
    @EnvironmentObject var m: MagicMessageProvider
    @EnvironmentObject var data: DataProvider

    @State var working = false
    @State var rotationAngle = 0.0
    @State var isGitProject = false

    static let shared = BtnGitPullView()

    private init() {}

    var body: some View {
        ZStack {
            if let project = data.project, self.isGitProject {
                MagicButton(icon: .iconDownload) { completion in
                    pull(path: project.path)
                    completion()
                }
                .magicShape(.circle)
                .magicStyle(.secondary)
                .magicShapeVisibility(.onHover)
                .help("从远程仓库拉取最新代码")
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
                                    rotationAngle -= 7
                                }
                            }
                        }
                    } else {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            rotationAngle = 0.0
                        }
                    }
                }
                .rotationEffect(.degrees(rotationAngle))
            } else {
                // 空状态占位符，确保视图始终有内容
                Color.clear.frame(width: 24, height: 24)
            }
        }
        .onAppear(perform: onAppear)
    }

    func pull(path: String) {
        withAnimation {
            working = true
        }

        // 显示加载状态
        m.loading("正在拉取远程代码...")

        do {
            try self.data.project?.pull()

            // 隐藏加载状态 - 成功消息会通过Project的事件系统自动显示
            m.hideLoading()
            m.success("代码拉取成功")
            self.reset()
        } catch let error {
            // 隐藏加载状态并显示错误
            m.hideLoading()
            self.reset()
            m.error("拉取失败: \(error.localizedDescription)")
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

extension BtnGitPullView {
    func updateIsGitProject() {
        self.isGitProject = data.project?.isGit() ?? false
    }
}

// MARK: - Event

extension BtnGitPullView {
    func onAppear() {
        self.updateIsGitProject()
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
