import SwiftUI

/// Git watcher plugin
/// Watches the selected project's .git directory and emits core project events.
class GitWatcherPlugin: NSObject, SuperPlugin {
    static var displayName: String = "Git Watcher"
    static var description: String = String(localized: "监听 .git 目录变化", table: "GitWatcher")
    static var iconName: String = "dot.radiowaves.left.and.right"
    static var allowUserToggle = false
    static var defaultEnabled: Bool = true
    static var order: Int = 23

    @objc static let shouldRegister = true
    @objc static var shared = GitWatcherPlugin()

    func addRootView<Content>(@ViewBuilder content: () -> Content) -> AnyView? where Content: View {
        AnyView(
            GitWatcherRootView {
                content()
            }
        )
    }
}
