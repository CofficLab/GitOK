import SwiftUI
import MagicCore
import OSLog

class SyncPlugin: SuperPlugin, SuperLog {
    let emoji = "🔄"
    var label: String = "Sync"
    var icon: String = "arrow.triangle.2.circlepath"
    var isTab: Bool = false

    func addDBView() -> AnyView {
        AnyView(EmptyView())
    }

    func addListView() -> AnyView {
        AnyView(EmptyView())
    }

    func addDetailView() -> AnyView {
        AnyView(EmptyView())
    }

    func addToolBarLeadingView() -> AnyView {
        AnyView(BtnSyncView())
    }

    func onInit() {
        os_log("\(self.t) onInit")
    }

    func onAppear() {
        os_log("\(self.t) onAppear")
    }

    func onDisappear() {
        os_log("\(self.t) onDisappear")
    }

    func onPlay() {
        os_log("\(self.t) onPlay")
    }

    func onPlayStateUpdate() {
        os_log("\(self.t) onPlayStateUpdate")
    }

    func onPlayAssetUpdate() {
        os_log("\(self.t) onPlayAssetUpdate")
    }
}

struct BtnSyncView: View, SuperLog, SuperEvent, SuperThread {
    @EnvironmentObject var m: MessageProvider
    @EnvironmentObject var g: DataProvider

    @State var working = false
    @State var rotationAngle = 0.0

    var commitMessage = CommitCategory.auto

    var body: some View {
        if let project = g.project {
            Button(action: {
                sync(path: project.path)
            }, label: {
                Label("同步", systemImage: "arrow.triangle.2.circlepath")
                    .rotationEffect(Angle(degrees: self.rotationAngle))
            })
            .disabled(working)
            .onChange(of: working) { newValue in
                let duration = 0.02
                if newValue {
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

        self.bg.async {
            do {
                try GitShell.pull(path)
                try GitShell.push(path)

                self.reset()
            } catch let error {
                self.reset()
                self.main.async {
                    m.alert("同步出错", info: error.localizedDescription)
                }
            }
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