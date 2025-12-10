import SwiftUI
import OSLog
import MagicAlert
import MagicCore

/// 状态栏文件信息 Tile：显示当前选中文件的文件名。
struct TileFile: View, SuperLog, SuperThread {
    @EnvironmentObject var a: AppProvider
    @EnvironmentObject var m: MagicMessageProvider
    @EnvironmentObject var data: DataProvider
    
    static let shared = TileFile()
    
    private init() {}
    
    var file: GitDiffFile? { data.file }

    var body: some View {
        if let file = file {
            let components = file.file.split(separator: "/").map(String.init)
            StatusBarTile(icon: "doc.text") {
                HStack(spacing: 4) {
                    ForEach(Array(components.enumerated()), id: \.offset) { idx, comp in
                        Text(comp)
                            .font(.footnote.weight(idx == components.count - 1 ? .semibold : .regular))
                            .foregroundColor(idx == components.count - 1 ? .primary : .secondary)
                        if idx < components.count - 1 {
                            Text("›")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
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
