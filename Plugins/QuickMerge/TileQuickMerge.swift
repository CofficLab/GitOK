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
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(hovered ? Color(.controlAccentColor).opacity(0.2) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 0))
        .popover(isPresented: $hovered, content: {
            VStack {
                Text("合并当前分支到主分支")
            }
            .frame(height: 40)
            .frame(width: 200)
        })
    }

    func merge() {
        self.bg.async {
            guard let project = project else {
                return
            }

            do {
                try git.mergeToMain(project.path, message: CommitCategory.CI.text + "Merge by GitOK")
            } catch let error {
                os_log(.error, "\(error.localizedDescription)")

                m.setError(error)
            }
        }
    }
}
