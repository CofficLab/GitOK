import MagicCore
import MagicShell
import MagicAlert
import OSLog
import SwiftUI

struct BtnMerge: View, SuperEvent, SuperThread {
    @EnvironmentObject var m: MagicMessageProvider

    var path: String
    var from: GitBranch
    var to: GitBranch

    @State private var isHovering = false

    var body: some View {
        Button("Merge", action: merge)
            .help("合并分支")
            .padding()
            .cornerRadius(8)
            .scaleEffect(isHovering ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isHovering)
            .onHover { hovering in
                isHovering = hovering
            }
    }

    func merge() {
        do {
            _ = try ShellGit.checkout(to.name, at: path)
            _ = try ShellGit.merge(from.name, at: path)
            self.m.info("已将 \(from.name) 合并到 \(to.name), 并切换到 \(to.name)")
        } catch let error {
            os_log(.error, "\(error.localizedDescription)")

            m.error(error.localizedDescription)
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
