import Foundation
import SwiftUI
import OSLog
import WebKit

#if os(iOS)
    typealias ViewRepresentable = UIViewRepresentable
#elseif os(macOS)
    typealias ViewRepresentable = NSViewRepresentable
#endif

// 将 WebContent 封装成一个普通的 View
struct WebView: ViewRepresentable {
    public init(
        url: URL? = nil,
        html: String? = "",
        code: String? = "",
        htmlFile: URL? = nil,
        config: WKWebViewConfiguration
    ) {
        os_log("🚩 初始化 Webview")
        self.url = url
        self.html = html
        self.config = config
        self.code = code
        self.htmlFile = htmlFile
        content = WebContent(frame: .zero, configuration: config)
        content.isInspectable = true
    }

    private let url: URL?
    private let html: String?
    private let code: String?
    private let htmlFile: URL?
    private let config: WKWebViewConfiguration?
    
    /// 网页内容
    var content: WebContent
    
    @StateObject var delegate = WebViewDelegate()

    #if os(iOS)
        public func makeUIView(context: Context) -> WKWebView {
            makeView()
        }

        public func updateUIView(_ uiView: WKWebView, context: Context) {}
    #endif

    #if os(macOS)
        public func makeNSView(context: Context) -> WKWebView {
            makeView()
        }

        public func updateNSView(_ content: WKWebView, context: Context) {
            // print("WebView 更新视图")
        }
    #endif

    func makeView() -> WKWebView {
        if url != nil {
            content.load(URLRequest(url: url!))
        }

        if html != "" {
            content.loadHTMLString(html!, baseURL: nil)
        }

        if htmlFile != nil {
            content.loadFileURL(htmlFile!, allowingReadAccessTo: htmlFile!)
        }

        if code != nil && code!.count > 0 {
            content.run(code!)
        }

        content.uiDelegate = delegate

        return content
    }
}

#Preview("APP") {
    AppPreview()
}
