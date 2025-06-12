import Foundation
import MagicCore
import OSLog
import SwiftData
import SwiftUI

class MessageProvider: ObservableObject, SuperLog, SuperThread, SuperEvent {
    let emoji = "📪"
    let maxMessageCount = 100

    @Published var messages: [SmartMessage] = []
    @Published var alert: String?
    @Published var error: Error?
    @Published var toast: String?
    @Published var doneMessage: String?
    @Published var alerts: [String] = []
    @Published var message: String = ""
    @Published var showDone = false
    @Published var showError = false
    @Published var showToast = false
    @Published var showAlert = false

    // 新的Toast管理器
    private let toastManager = ToastManager.shared

    init() {
        let verbose = false
        if verbose {
            os_log("\(Self.onInit) MessageProvider")
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
    
    func append(_ message: String, channel: String = "default", isError: Bool = false) {
        if !Thread.isMainThread {
            assertionFailure("append called from background thread")
        }

        self.messages.insert(SmartMessage(description: message, channel: channel, isError: isError), at: 0)
        if self.messages.count > self.maxMessageCount {
            self.messages.removeLast()
        }
    }

    // MARK: - 旧版本兼容方法（保持不变以维持兼容性）
    func alert(_ message: String, verbose: Bool = false) {
        if !Thread.isMainThread {
            assertionFailure("alert called from background thread")
        }

        if verbose {
            os_log("\(self.t)Alert: \(message)")
        }

        self.alert = message
        self.showAlert = true
    }

    func done(_ message: String) {
        if !Thread.isMainThread {
            assertionFailure("done called from background thread")
        }

        self.doneMessage = message
        self.showDone = true
    }

    func clearAlert() {
        if !Thread.isMainThread {
            assertionFailure("clearAlert called from background thread")
        }

        self.alert = nil
        self.showAlert = false
    }

    func clearDoneMessage() {
        if !Thread.isMainThread {
            assertionFailure("clearDoneMessage called from background thread")
        }

        self.doneMessage = nil
        self.showDone = false
    }

    func clearError() {
        if !Thread.isMainThread {
            assertionFailure("clearError called from background thread")
        }

        self.error = nil
        self.showError = false
    }

    func clearToast() {
        if !Thread.isMainThread {
            assertionFailure("clearToast called from background thread")
        }

        self.toast = nil
        self.showToast = false
    }

    func clearMessages() {
        if !Thread.isMainThread {
            assertionFailure("clearMessages called from background thread")
        }

        self.messages = []
    }

    func error(_ error: Error) {
        if !Thread.isMainThread {
            assertionFailure("error called from background thread")
        }

        self.error = error
        self.showError = true
    }
    
    func getAllChannels() -> [String] {
        let channels = Set(messages.map { $0.channel })
        return Array(channels).sorted()
    }

    func toast(_ toast: String) {
        if !Thread.isMainThread {
            assertionFailure("toast called from background thread")
        }

        self.toast = toast
        self.showToast = true
    }

    // MARK: - 新版本Toast方法
    
    /// 显示信息提示
    func showInfo(_ title: String, subtitle: String? = nil, duration: TimeInterval = 3.0) {
        toastManager.info(title, subtitle: subtitle, duration: duration)
    }
    
    /// 显示成功提示
    func showSuccess(_ title: String, subtitle: String? = nil, duration: TimeInterval = 3.0) {
        toastManager.success(title, subtitle: subtitle, duration: duration)
    }
    
    /// 显示警告提示
    func showWarning(_ title: String, subtitle: String? = nil, duration: TimeInterval = 4.0) {
        toastManager.warning(title, subtitle: subtitle, duration: duration)
    }
    
    /// 显示错误提示
    func showError(_ title: String, subtitle: String? = nil, autoDismiss: Bool = false) {
        toastManager.error(title, subtitle: subtitle, autoDismiss: autoDismiss)
    }
    
    /// 显示加载中提示
    func showLoading(_ title: String, subtitle: String? = nil) {
        toastManager.loading(title, subtitle: subtitle)
    }
    
    /// 隐藏加载中提示
    func hideLoading() {
        toastManager.dismissLoading()
    }
    
    /// 显示自定义提示
    func showCustom(
        systemImage: String,
        color: Color,
        title: String,
        subtitle: String? = nil,
        displayMode: ToastDisplayMode = .overlay,
        duration: TimeInterval = 3.0
    ) {
        toastManager.custom(
            systemImage: systemImage,
            color: color,
            title: title,
            subtitle: subtitle,
            displayMode: displayMode,
            duration: duration
        )
    }
    
    /// 隐藏所有Toast
    func dismissAllToasts() {
        toastManager.dismissAll()
    }
    
    // MARK: - 便捷方法，自动记录到消息列表
    
    /// 显示成功并记录消息
    func successWithLog(_ title: String, channel: String = "default") {
        showSuccess(title)
        append(title, channel: channel)
    }
    
    /// 显示错误并记录消息
    func errorWithLog(_ error: Error, channel: String = "default") {
        let title = "操作失败"
        let subtitle = error.localizedDescription
        showError(title, subtitle: subtitle)
        append("\(title): \(subtitle)", channel: channel, isError: true)
    }
    
    /// 显示信息并记录消息
    func infoWithLog(_ title: String, channel: String = "default") {
        showInfo(title)
        append(title, channel: channel)
    }
}

#Preview("Big Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
