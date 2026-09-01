import AppKit
import SwiftUI

// MARK: - Window Chrome

/// 配置 GitOK 窗口 chrome：与 Lumi 的 `configureForLumiMinimalChrome` 一致，
/// 内容延伸到标题栏区域（fullSizeContentView），红绿灯悬浮在自绘工具栏上，
/// 从而让顶部工具栏完全由应用自身绘制，不再受系统版本（macOS 14/15/26）
/// 原生标题栏/工具栏渲染差异影响。
public extension NSWindow {
    func configureForGitOKMinimalChrome() {
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        toolbar = nil
        styleMask.insert(.fullSizeContentView)

        // 根因修复：GitOK 内容里的 NavigationSplitView 会触发 SwiftUI 创建
        // unified toolbar，进而把 NSTitlebarContainerView 设为 isHidden=true 且
        // alphaValue=0——整条 titlebar（含红绿灯按钮）因此不渲染。该隐藏发生在
        // SwiftUI 完成窗口布局之后，所以这里延迟到布局完成后，沿红绿灯按钮的
        // 祖先链找到该容器并恢复可见与 alpha，红绿灯即重新悬浮在自绘顶栏上。
        // 对齐 Lumi（其内容用自绘 split、无 NavigationSplitView，不触发此问题）。
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: { [weak self] in
            guard let w = self else { return }
            w.titlebarAppearsTransparent = true
            w.titleVisibility = .hidden
            var v: NSView? = w.standardWindowButton(.closeButton)?.superview
            while let view = v {
                if String(describing: type(of: view)).contains("TitlebarContainer") {
                    view.isHidden = false
                    view.alphaValue = 1.0
                    break
                }
                v = view.superview
            }
        })
    }
}

/// 解析宿主 NSWindow 并应用 chrome 配置的辅助视图。
public struct WindowAccessor: NSViewRepresentable {
    public let onResolve: (NSWindow) -> Void

    public init(onResolve: @escaping (NSWindow) -> Void) {
        self.onResolve = onResolve
    }

    public func makeNSView(context: Context) -> NSView {
        let view = HostView(onResolve: onResolve)
        view.resolveWindowIfAttached()
        return view
    }

    public func updateNSView(_ nsView: NSView, context: Context) {
        (nsView as? HostView)?.resolveWindowIfAttached()
    }

    final class HostView: NSView {
        let onResolve: (NSWindow) -> Void

        init(onResolve: @escaping (NSWindow) -> Void) {
            self.onResolve = onResolve
            super.init(frame: .zero)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            resolveWindowIfAttached()
        }

        func resolveWindowIfAttached() {
            guard let window else { return }
            onResolve(window)
        }
    }
}

/// 整条自绘顶栏的窗口拖拽区：`mouseDownCanMoveWindow` 允许用户
/// 拖拽顶栏（红绿灯以外的空白区域）移动窗口。
struct WindowDragRegion: NSViewRepresentable {
    func makeNSView(context: Context) -> DragRegionView {
        DragRegionView()
    }

    func updateNSView(_ nsView: DragRegionView, context: Context) {}
}

final class DragRegionView: NSView {
    override var mouseDownCanMoveWindow: Bool {
        true
    }
}
