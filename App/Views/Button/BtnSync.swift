import SwiftUI

struct BtnSync: View, SuperLog, SuperEvent, SuperThread {
    @EnvironmentObject var app: AppProvider

    @Binding var message: String

    @State var working = false
    @State private var rotationAngle: Double = 0

    var path: String
    var commitMessage = CommitCategory.auto
    var git = Git()

    var body: some View {
        Button(action: save, label: {
            Label("保存", systemImage: "arrow.trianglehead.2.clockwise.rotate.90")
                .rotationEffect(Angle(degrees: rotationAngle))
                .animation(working ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: rotationAngle)
        }).disabled(working)
    }

    func save() {
        withAnimation {
            working = true
            rotationAngle = 360
        }

        self.bg.async {
            do {
                try git.push(path)

                self.reset()
            } catch let error {
                self.reset()
                self.main.async {
                    app.alert("同步出错", info: error.localizedDescription)
                }
            }
        }
    }

    func alert(error: Error) {
        self.main.async {
            app.alert("同步出错", info: error.localizedDescription)
        }
    }

    func reset() {
        self.main.async {
            withAnimation {
                self.working = false
                self.rotationAngle = 0
            }
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
