import OSLog
import SwiftUI
import MagicKit

struct BtnSync: View, SuperLog, SuperEvent, SuperThread {
    @EnvironmentObject var m: MessageProvider
    @EnvironmentObject var g: GitProvider

    @Binding var message: String

    @State var working = false
    @State var rotationAngle = 0.0

    var path: String
    var commitMessage = CommitCategory.auto

    var body: some View {
        Button(action: sync, label: {
            Label("同步", systemImage: "arrow.trianglehead.2.clockwise.rotate.90")
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

    func sync() {
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

#Preview {
    AppPreview()
        .frame(width: 800)
}
