import Combine
import ProviderChatSection
import ProviderRootView
import SwiftUI

/// 根布局的右侧面板描述。
///
/// 继承共享 `RootViewPane` 的尺寸与显隐契约，额外提供 ChatSection
/// 绑定、原生全屏窗口与关闭回调等 GitOK 宿主能力。
@MainActor
public final class RootTrailingPane: RootViewPane {
    @Published public private(set) var width: ChatSectionWidth
    /// Whether this pane exposes the native window full-screen toggle in its toolbar.
    public let supportsFullScreen: Bool
    /// Called when the pane should be presented in a dedicated full-screen window.
    public var onFullScreen: (@MainActor () -> Void)?
    /// Called when the user dismisses the pane from its own toolbar.
    /// Consumers can use this callback to clear the selection that caused
    /// the pane to be shown.
    public var onDismiss: (@MainActor () -> Void)?
    private var visibilityObserver: (any ChatSectionProvidingObserverHandle)?
    private var widthObserver: (any ChatSectionProvidingObserverHandle)?
    private var widthResizeHandler: (@MainActor (CGFloat) -> Void)?

    public init(
        id: String,
        minWidth: CGFloat = 280,
        idealWidth: CGFloat = 320,
        maxWidth: CGFloat = .infinity,
        width: ChatSectionWidth? = nil,
        isVisible: Bool = true,
        supportsFullScreen: Bool = false,
        onDismiss: (@MainActor () -> Void)? = nil,
        content: AnyView
    ) {
        let resolvedWidth = width ?? ChatSectionWidth(
            minWidth: minWidth,
            idealWidth: idealWidth,
            maxWidth: maxWidth
        )
        self.width = resolvedWidth
        self.supportsFullScreen = supportsFullScreen
        self.onFullScreen = nil
        self.onDismiss = onDismiss
        super.init(
            id: id,
            minWidth: resolvedWidth.minWidth,
            idealWidth: resolvedWidth.idealWidth,
            maxWidth: resolvedWidth.maxWidth,
            isVisible: isVisible,
            content: content
        )
    }

    /// Presents this pane's content in a dedicated macOS window and enters native
    /// full-screen mode. The original trailing pane remains unchanged underneath.
    public func presentFullScreen() {
        #if os(macOS)
        if let fullScreenWindowController {
            fullScreenWindowController.present()
        } else {
            createFullScreenWindowController().present()
        }
        #endif
    }

    #if os(macOS)
    private var fullScreenWindowController: TrailingPaneFullScreenWindowController?

    private func createFullScreenWindowController() -> TrailingPaneFullScreenWindowController {
        let controller = TrailingPaneFullScreenWindowController(content: content) { [weak self] in
            self?.fullScreenWindowController = nil
        }
        fullScreenWindowController = controller
        return controller
    }
    #endif

    /// 将面板显隐状态绑定到 ChatSection Provider。
    ///
    /// ChatPanel 通过 `ChatSectionProviding` 响应侧边栏切换；根布局
    /// 直接观察这个状态。
    @MainActor
    public func bindVisibility(to provider: any ChatSectionProviding) {
        isVisible = provider.isVisible
        visibilityObserver?.cancel()
        visibilityObserver = provider.addObserver { [weak self] event in
            guard case let .visibilityChanged(visible) = event else { return }
            Task { @MainActor [weak self] in
                self?.isVisible = visible
            }
        }
    }

    /// 将面板宽度绑定到 ChatSection provider，并接收用户拖拽完成后的宽度。
    @MainActor
    public func bindWidth(
        to provider: any ChatSectionProviding,
        onResize: @escaping @MainActor (CGFloat) -> Void
    ) {
        applyWidth(provider.chatSectionWidth)
        widthResizeHandler = onResize
        widthObserver?.cancel()
        widthObserver = provider.addObserver { [weak self] event in
            guard case let .widthChanged(width) = event else { return }
            Task { @MainActor [weak self] in
                self?.applyWidth(width)
            }
        }
    }

    /// 直接设置面板宽度（由面板调整回调调用），自动 clamp 到 min/max 范围内。
    @MainActor
    public func setWidth(_ width: CGFloat) {
        applyWidth(self.width.withIdealWidth(self.width.clamped(width)))
    }

    /// 转发用户拖拽后的面板宽度。
    @MainActor
    override public func saveWidth(_ width: CGFloat) {
        widthResizeHandler?(width)
    }

    private func applyWidth(_ newWidth: ChatSectionWidth) {
        guard width != newWidth else { return }
        width = newWidth
        updateDimensions(
            minWidth: newWidth.minWidth,
            idealWidth: newWidth.idealWidth,
            maxWidth: newWidth.maxWidth
        )
    }
}