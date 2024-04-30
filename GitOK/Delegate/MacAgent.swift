import Foundation
import SwiftData
import SwiftUI
import CloudKit
import OSLog

class MacAgent: NSObject, NSApplicationDelegate, ObservableObject {
    func application(
        _ application: NSApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        os_log("\(Thread.isMainThread ? "[主]" : "[后]") 已注册远程通知")
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        os_log("\(Thread.isMainThread ? "[主]" : "[后]") Finish Lanunching")
    }

    func applicationWillTerminate(_ notification: Notification) {
        os_log("\(Thread.isMainThread ? "[主]" : "[后]") Will Terminate")
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        //Logger.app.debug("Did Become Active")
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        os_log("\(Thread.isMainThread ? "[主]" : "[后]") Will Finish Launching")
    }

    // 收到远程通知
    // 如果改动由本设备发出：
    //  本设备：不会收到远程通知
    //  其他设备：会收到远程通知
    func application(
        _ application: NSApplication,
        didReceiveRemoteNotification userInfo: [String: Any]
    ) {
        os_log("\(Thread.isMainThread ? "[主]" : "[后]") 收到远程通知\n\(userInfo)")
    }
}

#Preview("APP") {
    RootView(content: {
        Content()
    }).frame(width: 700, height: 600)
}
