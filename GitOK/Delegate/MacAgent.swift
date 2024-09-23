import Foundation
import SwiftData
import SwiftUI
import CloudKit
import OSLog

class MacAgent: NSObject, NSApplicationDelegate, ObservableObject {
    var label: String {"\(Logger.isMain)🍎 MacAgent::"}
    
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
        EventManager().emitDidBecomeActive()
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        let verbose = false 
        if verbose {
            os_log("\(self.label)Will Finish Launching")
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
        Content()
    }).frame(width: 700, height: 600)
}
