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

        do {
            try GitShell.pull(path)
            try GitShell.push(path)

            self.reset()
        } catch let error {
            self.reset()
            m.alert("同步出错", info: error.localizedDescription)
        }
    }

    func alert(error: Error) {
        self.main.async {
            m.alert("同步出错", info: error.localizedDescription)
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
