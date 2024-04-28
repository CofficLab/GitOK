import SwiftUI
import WebKit
import OSLog

class WebAgent: NSObject, WKScriptMessageHandler {
    private var eventManager = EventManager()
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "sendMessage" {
            let data = message.body as! [String: String]
            let channel = WebChannel.from(data["channel"] ?? "")
            
            os_log("📶 JS 消息通道：\(channel.name)")
            
            switch channel {
            case .downloadFile:
                downloadFile(message: message)
            case .pageLoaded:
                pageLoaded(message: message)
            case .unknown(let c):
                os_log("JS 消息来自未知通道：\(c)")
            }
        } else {
            os_log("收到JS发送的消息但未处理：\(message.name)")
        }
    }
    
    func pageLoaded(message: WKScriptMessage) {
        os_log("📶 JS Said: Ready")
    }
    
    func downloadFile(message: WKScriptMessage) {
        os_log("📶 JS Said: DownloadFile")
        
        let data = message.body as! [String: String]
        
        downloadFile(base64: data["base64"] ?? "", name: data["name"] ?? "")
    }
    
    func updateDrawing(message: WKScriptMessage) {
        os_log("📶 JS Said: UpdateDrawing")
    }
    
    func downloadFile(base64: String, name: String) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        if panel.runModal() == .OK, let url = panel.url {
            guard let base64Data = Data(base64Encoded: base64) else {
                print("Base64 decode failed")
                return
            }
            
            do {
                try base64Data.write(to: url.appendingPathComponent(name))
                print("保存成功")
            } catch {
                print("保存失败 -> \(error)")
            }
        } else {
        }
    }
}

#Preview {
    AppPreview()
}
