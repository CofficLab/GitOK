import SwiftUI
import WebKit
import OSLog
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

struct ResponseBody: View {
    let response: APIResponse?
    
    @State private var viewMode: ViewMode = .pretty

    enum ViewMode {
        case pretty, raw, preview, visualize
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Picker("", selection: $viewMode) {
                    Text("Pretty").tag(ViewMode.pretty)
                    Text("Raw").tag(ViewMode.raw)
                    Text("Preview").tag(ViewMode.preview)
                    Text("Visualize").tag(ViewMode.visualize)
                }
                .pickerStyle(.segmented)

                Spacer()
            }

            if let body = response?.body {
                switch viewMode {
                case .pretty:
                    PrettyView(content: body)
                case .raw:
                    RawView(content: body)
                case .preview:
                    PreviewView(content: body)
                case .visualize:
                    VisualizeView(content: body)
                }
            }
        }
    }
}

struct PrettyView: View {
    let content: String
    
    var formattedBody: String {
        guard let data = content.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data),
              let prettyData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
              let prettyString = String(data: prettyData, encoding: .utf8) else {
            return content
        }
        return prettyString
    }
    
    var body: some View {
        ScrollView {
            Text(formattedBody)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
        }
    }
}

struct RawView: View {
    let content: String
    
    var body: some View {
        ScrollView {
            Text(content)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
        }
    }
}

struct PreviewView: View {
    let content: String
    
    var body: some View {
        ScrollView {
            if content.lowercased().contains("<!doctype html") || content.lowercased().contains("<html") {
                ResponseWebView(htmlString: content)
            } else if let imageData = Data(base64Encoded: content) {
                #if os(iOS)
                if let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                }
                #else
                if let nsImage = NSImage(data: imageData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFit()
                }
                #endif
            } else {
                Text("Cannot preview this content type")
            }
        }
    }
}

struct VisualizeView: View {
    let content: String
    
    var body: some View {
        ScrollView {
            if let data = content.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                JsonTreeView(json: json)
            } else {
                Text("Cannot visualize this content")
            }
        }
    }
}

#if os(iOS)
struct ResponseWebView: UIViewRepresentable {
    let htmlString: String
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.isScrollEnabled = true
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(htmlString, baseURL: nil)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // 页面加载完成后的处理
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("WebView loading failed: \(error.localizedDescription)")
        }
    }
}
#else
struct ResponseWebView: NSViewRepresentable {
    let htmlString: String
    
    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(htmlString, baseURL: nil)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: ResponseWebView
        
        init(_ parent: ResponseWebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // 页面加载完成后的处理
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("WebView loading failed: \(error.localizedDescription)")
        }
    }
}
#endif

struct JsonTreeView: View {
    let json: [String: Any]
    
    var body: some View {
        VStack(alignment: .leading) {
            ForEach(Array(json.keys), id: \.self) { key in
                VStack(alignment: .leading) {
                    Text(key)
                        .bold()
                    if let value = json[key] {
                        Text(String(describing: value))
                            .padding(.leading)
                    }
                }
            }
        }
        .padding()
    }
}
