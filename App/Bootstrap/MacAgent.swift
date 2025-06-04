import CloudKit
import Foundation
import MagicCore
import OSLog
import SwiftData
import SwiftUI

class MacAgent: NSObject, NSApplicationDelegate, ObservableObject, SuperLog, SuperEvent {
    var label: String { "🍎 MacAgent::" }

    func application(
        _ application: NSApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        os_log("\(self.label)已注册远程通知")
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let verbose = false
        if verbose {
            os_log("\(self.label)Finish Lanunching")
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        let verbose = false
        if verbose {
            os_log("\(self.label)Will Terminate")
        }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        let verbose = false
        if verbose {
            os_log("\(self.label)Did Become Active")
        }

        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .appDidBecomeActive, object: self)
        }
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        let verbose = false
        if verbose {
            os_log("\(self.label)Will Finish Launching")
        }
    }

    func applicationWillBecomeActive(_ notification: Notification) {
        let verbose = false
        if verbose {
            os_log("\(self.label)Will Become Active")
        }

        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .appWillBecomeActive, object: self)
        }
    }

    // 收到远程通知
    // 如果改动由本设备发出：
    //  本设备：不会收到远程通知
    //  其他设备：会收到远程通知
    func application(
        _ application: NSApplication,
        didReceiveRemoteNotification userInfo: [String: Any]
    ) {
        let verbose = false
        if verbose {
            os_log("\(self.label)收到远程通知\n\(userInfo)")
        }
    }
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    }).frame(width: 700, height: 600)
}

#Preview("Big Screen") {
    RootView {
        ContentView()
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
