import MagicCore
import SwiftUI

struct BtnSyncView: View, SuperLog, SuperEvent, SuperThread {
    @EnvironmentObject var m: MessageProvider
    @EnvironmentObject var data: DataProvider

    @State var working = false
    @State var rotationAngle = 0.0

    var commitMessage = CommitCategory.auto
    
    static let shared = BtnSyncView()
    
    private init() {}

    var body: some View {
        if let project = data.project, project.isGit {
            Button(action: {
                sync(path: project.path)
            }, label: {
                Label("同步", systemImage: "arrow.triangle.2.circlepath")
                    .rotationEffect(Angle(degrees: self.rotationAngle))
            })
            .disabled(working)
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

    func sync(path: String) {
        withAnimation {
            working = true
        }

        // 显示加载状态
        m.showLoading("正在同步...")

        do {
            try self.data.project?.sync()
            
            // 隐藏加载状态 - 成功消息会通过Project的事件系统自动显示
            m.hideLoading()
            self.reset()
        } catch let error {
            // 隐藏加载状态并显示错误
            m.hideLoading()
            self.reset()
            m.errorWithLog(error, channel: "🔄 sync")
        }
    }

    func alert(error: Error) {
        self.main.async {
            m.errorWithLog(error, channel: "🔄 sync")
        }
    }

    func reset() {
        withAnimation {
            self.working = false
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
