import Foundation
import OSLog
import WebKit
import SwiftUI

/// 负责渲染 Web 内容，与 JS 交互等
class WebContent: WKWebView {    
    // MARK: 执行JS代码

    func run(_ jsCode: String) {
        let trimmed = jsCode.trimmingCharacters(in: .whitespaces)
        let shortJsCode = trimmed.count <= 30 ? trimmed : String(jsCode.prefix(30)) + "..."
        
        guard jsCode.count > 0 else {
            return os_log("📶 执行JS代码，代码为空，放弃执行")
        }

        os_log("📶 JS Code: \(shortJsCode)")
        DispatchQueue.main.async {
            self.evaluateJavaScript(jsCode, completionHandler: { _, error in
                if error == nil {
                    os_log("📶 执行JS代码成功")
                } else {
                    os_log("📶 执行JS代码失败-> \(String(describing: error))")
                }
            })
        }
    }
}

#Preview {
    AppPreview()
}
