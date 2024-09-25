import Foundation
import OSLog
import SwiftData
import SwiftUI

class MessageProvider: ObservableObject, SuperLog, SuperThread, SuperEvent {
    @Published var messages: [SmartMessage] = []
    @Published var alerts: [String] = []
    @Published var error: Error? = nil
    @Published var message: String = ""

    init() {
        let verbose = false
        if verbose {
            os_log("\(Logger.initLog) MessageProvider")
        }
    }
    
    func alert(_ message: String, info: String) {
        // 显示错误提示
        let errorAlert = NSAlert()
        errorAlert.messageText = message
        errorAlert.informativeText = info
        errorAlert.alertStyle = .critical
        errorAlert.addButton(withTitle: "好的")
        errorAlert.runModal()
    }
    
    func setError(_ e: Error) {
        self.alert("发生错误", info: e.localizedDescription)
    }

    func setFlashMessage(_ m: String) {
        message = m
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.message = ""
        }
        
        self.append(m)
    }

    func clearError() {
        self.error = nil
    }

    func append(_ message: String) {
        main.async {
            self.messages.insert(SmartMessage(description: message), at: 0)
            self.main.asyncAfter(deadline: .now() + 3) {
                if self.messages.count > 10 {
                    _ = self.messages.popLast()
                }
            }
        }
    }
}
