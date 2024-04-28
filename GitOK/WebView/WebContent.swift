import Foundation
import OSLog
import WebKit

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
        evaluateJavaScript(jsCode, completionHandler: { _, error in
            if error == nil {
                os_log("📶 执行JS代码成功")
            } else {
                os_log("📶 执行JS代码失败-> \(String(describing: error))")
            }
        })
    }

    /// 以同步的方式与 JS 通信，获取当前的 NodeType
    @objc func getNodeType() -> String {
        dispatchPrecondition(condition: .onQueue(.main))

        var result: String?

        evaluateJavaScript("api.app.selectionType") { response, error in
            if error != nil {
                result = ""
                return
            }

            result = response as? String ?? ""
        }

        while result == nil {
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.01))
        }

        return result ?? ""
    }
}
