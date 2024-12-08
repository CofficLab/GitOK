import MagicKit
import OSLog
import SwiftUI

struct TileQuickMerge: View, SuperLog, SuperThread {
    @EnvironmentObject var m: MessageProvider
    @EnvironmentObject var g: GitProvider

    @State var hovered = false

    var git = Git()
    var project: Project? { g.project }

    var body: some View {
        HStack {            
            Image(systemName: "arrowshape.zigzag.forward")
        }
        .onHover(perform: { hovering in
            hovered = hovering
        })
        .onTapGesture {
            merge()
            self.m.toast("已合并到主分支")
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(hovered ? Color(.controlAccentColor).opacity(0.2) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 0))
    }

    func merge() {
        self.bg.async {
            os_log("\(self.t)QuickMerge")
            
            guard let project = project else {
                os_log(.error, "\(self.t)No project")
                return
            }

            do {
                try git.mergeToMain(project.path)
            } catch let error {
                os_log(.error, "\(error.localizedDescription)")

                m.setError(error)
            }
        }
    }
}
