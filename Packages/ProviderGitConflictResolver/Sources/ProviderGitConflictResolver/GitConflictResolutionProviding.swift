/// 跨插件的冲突解决界面入口。
///
/// 该协议只表达“请求展示”这一个 UI 能力，不暴露冲突插件的 ViewModel、
/// SwiftUI View 或具体弹层实现。工作区插件可以依赖它，而不依赖冲突插件本身。
@MainActor
public protocol GitConflictResolutionProviding: AnyObject {
    /// 请求展示当前项目的冲突解决界面。
    ///
    /// 实现方负责重新读取当前项目状态；调用方不需要知道弹层如何挂载。
    func requestPresentation()
}
