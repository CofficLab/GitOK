import LumiUI
import ProviderToast
import SwiftUI

// MARK: - Toast Overlay

/// 挂在主窗口根部的 Toast 渲染覆盖层。
///
/// 订阅共享的 `ToastCenter`（即 `ToastProviding` 实现），在窗口顶部
/// 渲染当前 toast；持久化错误则以居中面板呈现。
/// Toast 本身不参与交互（`allowsHitTesting(false)`），不遮挡下方内容。
/// 具体视觉由 LumiUI 组件承担（见 `ToastBannerView` / `ErrorNoticeOverlay`）。
public struct ToastOverlay<Content: View>: View {
    private let content: Content
    @ObservedObject private var center: ToastCenter
    @LumiMotionPreferenceReader private var motionPreference

    public init(content: Content, center: ToastCenter) {
        self.content = content
        self.center = center
    }

    public var body: some View {
        content
            .overlay(alignment: .top) {
                Group {
                    if let toast = center.currentToast {
                        ToastBannerView(toast: toast)
                            .appStatusPresentationTransition(preference: motionPreference)
                    }
                }
                .animation(
                    LumiMotion.enabled(LumiMotion.statusPresentation, preference: motionPreference),
                    value: center.currentToast
                )
                .allowsHitTesting(false)
            }
            .overlay {
                if let error = center.currentError {
                    ErrorNoticeOverlay(error: error, center: center)
                }
            }
    }
}

// MARK: - Preview

@MainActor
private struct ToastOverlayPreviewHost: View {
    private let center: ToastCenter

    init(style: LumiToastStyle, detail: String?) {
        let center = ToastCenter()
        center.show(
            LumiToast(
                title: "Commit selected",
                detail: detail,
                style: style,
                // 预览中保持常驻，避免自动消失后预览空白。
                duration: 3600
            )
        )
        self.center = center
    }

    var body: some View {
        ToastOverlay(content: Color.lumiControlBackground, center: center)
    }
}

#Preview("App - Large") {
    ToastOverlayPreviewHost(style: .info, detail: "a1b2c3d")
        .inRootView()
        .frame(width: 600, height: 400)
}

#Preview("App - Small") {
    ToastOverlayPreviewHost(style: .success, detail: nil)
        .inRootView()
        .frame(width: 360, height: 300)
}
