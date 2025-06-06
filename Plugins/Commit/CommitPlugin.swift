import SwiftUI
import MagicCore
import OSLog

/**
 * Commit插件 - 负责显示和管理Git提交列表
 */
class CommitPlugin: SuperPlugin, SuperLog {
    let emoji = "🍒"
    var label: String = "Commit"
    var icon: String = "doc.text"
    var isTab: Bool = true

    /**
     * 添加数据库视图
     */
    func addDBView() -> AnyView {
        AnyView(EmptyView())
    }

    /**
     * 添加列表视图 - 显示提交列表
     */
    func addListView(tab: String) -> AnyView {
        if tab == GitPlugin().label {
            AnyView(CommitList().environmentObject(GitProvider.shared))
        } else {
            AnyView(EmptyView())
        }
    }

    /**
     * 添加详情视图
     */
    func addDetailView() -> AnyView {
        AnyView(EmptyView())
    }

    /**
     * 插件初始化
     */
    func onInit() {
        os_log("\(self.t) onInit")
    }

    /**
     * 插件出现时
     */
    func onAppear() {
        os_log("\(self.t) onAppear")
    }

    /**
     * 插件消失时
     */
    func onDisappear() {
        os_log("\(self.t) onDisappear")
    }

    /**
     * 播放时
     */
    func onPlay() {
        os_log("\(self.t) onPlay")
    }

    /**
     * 播放状态更新时
     */
    func onPlayStateUpdate() {
        os_log("\(self.t) onPlayStateUpdate")
    }

    /**
     * 播放资源更新时
     */
    func onPlayAssetUpdate() {
        os_log("\(self.t) onPlayAssetUpdate")
    }
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    })
    .frame(width: 800, height: 800)
}

#Preview("App-Big Screen") {
    RootView {
        ContentView()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
