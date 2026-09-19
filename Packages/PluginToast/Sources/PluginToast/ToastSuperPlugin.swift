import Combine
import Foundation
import KernelCore
import KitSuperLog
import os
import ProviderDocsView
import ProviderRootView
import ProviderToast

// MARK: - Toast SuperPlugin

/// Toast 插件：实现 `ToastProviding` 能力。
///
/// 在 `onBoot` 中注册 `ToastCenter`（替换式节流 + 自动消失 + 持久错误面板），并通过
/// `RootViewProviding` 的覆盖层（overlays）把 `ToastOverlay` 挂到根视图，
/// 让所有 toast 显示在窗口顶部。
/// 任何持有内核的代码可通过
/// `kernel.resolveProvider((any ToastProviding).self)?.show(...)` 发出提示。
@MainActor
public final class ToastSuperPlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.toast", category: "Toast")
    public let id = "com.coffic.gitok.plugin.toast"
    /// 尽早替换 ToastProviding 为真实状态机（ToastCenter），
    /// 保证后续插件在 onBoot 中 resolve 到的是可用的 toast 能力。
    public let order = 10
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.toast",
        name: "Toast",
        description: "Transient toast notifications overlay",
        category: .core,
        stage: .stable,
        policy: .required
    )

    /// Toast 状态机，由根覆盖层订阅渲染。
    public let center = ToastCenter()

    /// 覆盖层稳定 ID（供挂载/撤回）。
    static let overlayID = "toast"

    public init() {}

    public func onRegister(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any DocsViewProviding).self)?.addAbout(
            DocsEntry(id: id, name: metadata.name) { ToastAboutView() }
        )
    }

    public func onUnregister(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any DocsViewProviding).self)?.removeEntries(id: id)
    }

    public func onBoot(kernel: KernelCoreContainer) throws {
        // 替换宿主的默认 no-op 实现为真实状态机。
        kernel.unregisterProvider((any ToastProviding).self)
        try kernel.registerProvider((any ToastProviding).self, center)

        // 挂载渲染覆盖层：wrap 在根视图最外层，位于窗口顶部。
        guard let rootView = kernel.resolveProvider((any RootViewProviding).self) else {
            Self.logger.error("\(self.t)RootViewProviding not registered; skip overlay mount")
            return
        }
        let center = self.center
        rootView.addOverlays([
            RootOverlayItem(id: Self.overlayID, order: 10000) { content in
                ToastOverlay(content: content, center: center)
            },
        ])
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        center.dismiss()
        kernel.resolveProvider((any RootViewProviding).self)?
            .removeOverlays(ids: [Self.overlayID])
    }
}
