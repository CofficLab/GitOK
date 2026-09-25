#if os(macOS)
import AppKit
import SwiftUI

/// Owns the separate native window used to display a trailing pane full screen.
@MainActor
final class TrailingPaneFullScreenWindowController: NSObject, NSWindowDelegate {
    private let content: AnyView
    private let onClose: @MainActor () -> Void
    private var window: NSWindow?

    init(content: AnyView, onClose: @escaping @MainActor () -> Void) {
        self.content = content
        self.onClose = onClose
    }

    func present() {
        if let window {
            window.makeKeyAndOrderFront(nil)
            return
        }

        let window = NSWindow(
            contentRect: NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1_200, height: 800),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Diff"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.collectionBehavior = [.fullScreenPrimary, .managed]
        window.contentView = NSHostingView(rootView: content)
        window.delegate = self
        self.window = window

        window.makeKeyAndOrderFront(nil)
        DispatchQueue.main.async { [weak window] in
            guard let window, !window.styleMask.contains(.fullScreen) else { return }
            window.toggleFullScreen(nil)
        }
    }

    func windowWillClose(_ notification: Notification) {
        window = nil
        onClose()
    }
}
#endif
