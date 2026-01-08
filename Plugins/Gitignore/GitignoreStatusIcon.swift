import MagicKit
import SwiftUI

/// .gitignore 状态栏图标：存在 .gitignore 时可点击查看。
struct GitignoreStatusIcon: View, SuperLog {
    @EnvironmentObject var data: DataProvider

    @State private var isSheetPresented = false
    @State private var hasGitignore = false

    static let shared = GitignoreStatusIcon()

    init() {}

    var body: some View {
        StatusBarTile(icon: "doc.text.fill", onTap: {
            if hasGitignore {
                isSheetPresented.toggle()
            }
        })
        .help(hasGitignore ? "查看 .gitignore 文件" : "未找到 .gitignore 文件")
        .sheet(isPresented: $isSheetPresented) {
            GitignoreViewer()
                .frame(minWidth: 800, minHeight: 600)
        }
        .onAppear(perform: checkGitignoreExistence)
        .onChange(of: data.project, checkGitignoreExistence)
    }

    private func checkGitignoreExistence() {
        guard let project = data.project else {
            hasGitignore = false
            return
        }

        Task {
            do {
                _ = try await project.getGitignoreContent()
                await MainActor.run {
                    self.hasGitignore = true
                }
            } catch {
                await MainActor.run {
                    self.hasGitignore = false
                }
            }
        }
    }
}

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}

