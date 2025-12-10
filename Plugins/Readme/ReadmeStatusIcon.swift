import AppKit
import MagicCore
import OSLog
import SwiftUI

/// README 状态栏图标：存在 README 时可点击弹出查看。
struct ReadmeStatusIcon: View, SuperLog {
    @EnvironmentObject var data: DataProvider
    
    @State private var isSheetPresented = false
    @State private var hasReadme = false
    
    static let shared = ReadmeStatusIcon()
    
    init() {}
    
    var body: some View {
        StatusBarTile(icon: "doc.text.magnifyingglass", onTap: {
            if hasReadme {
                isSheetPresented.toggle()
            }
        })
        .help(hasReadme ? "查看 README.md 文档" : "未找到 README.md 文件")
        .sheet(isPresented: $isSheetPresented) {
            ReadmeViewer()
                .frame(minWidth: 800, minHeight: 600)
        }
        .onAppear(perform: checkReadmeExistence)
        .onChange(of: data.project, checkReadmeExistence)
    }
    
    private func checkReadmeExistence() {
        guard let project = data.project else {
            hasReadme = false
            return
        }
        
        Task {
            do {
                _ = try await project.getReadmeContent()
                await MainActor.run {
                    self.hasReadme = true
                }
            } catch {
                await MainActor.run {
                    self.hasReadme = false
                }
            }
        }
    }
}

#Preview("ReadmeStatusIcon") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
} 