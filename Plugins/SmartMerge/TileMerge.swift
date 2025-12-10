import MagicCore
import MagicAlert
import OSLog
import SwiftUI

/// SmartMerge 状态栏按钮：点击弹出合并表单。
struct TileMerge: View, SuperLog, SuperThread {
    @EnvironmentObject var m: MagicMessageProvider

    @State var isPresented = false
    
    static let shared = TileMerge()
    
    private init() {}

    var body: some View {
        StatusBarTile(icon: "arrow.trianglehead.merge", onTap: {
            self.isPresented.toggle()
        }) {
            EmptyView()
        }
        .popover(isPresented: $isPresented, content: {
            VStack {
                MergeForm().padding()
            }
            .frame(height: 250)
            .frame(width: 200)
        })
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
