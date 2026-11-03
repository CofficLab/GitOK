import KernelCore
import SwiftUI

@MainActor
public enum FactoryGitOK {
    public static func makeKernel() throws -> KernelCoreContainer {
        try KernelFactory.makeKernel()
    }

    public static func makeMainView(kernel: KernelCoreContainer) throws -> AnyView {
        try KernelFactory.makeMainView(kernel: kernel)
    }

    /// 使用已装配的内核组装设置视图，供专用 App 的 `Window` scene 使用。
    public static func makeSettingsView(kernel: KernelCoreContainer) throws -> AnyView {
        try KernelFactory.makeSettingsView(kernel: kernel)
    }

    /// 打开外部传入的目录：加入项目列表并切换为当前项目。
    ///
    /// CLI 脚本 `gitok <path>` 通过 `gitok://open?path=...` 触发此入口。
    ///
    /// - Parameters:
    ///   - path: 目录路径（可含 `~`）。
    ///   - kernel: 已装配的内核。
    /// - Returns: 目录有效且已成功切换当前项目时为 `true`。
    @discardableResult
    public static func openExternalPath(
        _ path: String,
        kernel: KernelCoreContainer
    ) -> Bool {
        KernelFactory.openExternalPath(path, kernel: kernel)
    }
}
