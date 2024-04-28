import SwiftUI
import WebKit
import OSLog

class DefaultHanlder: NSObject, WKScriptMessageHandler {
    static var channel: String = "sendMessage"

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        os_log("收到JS发送的消息但未处理：\(message.name)")
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
