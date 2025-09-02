import Foundation
import SwiftUI

extension Notification.Name {
    static let appReady = Notification.Name("appReady")
    static let appExit = Notification.Name("appExit")
    static let appError = Notification.Name("appError")
    static let appLog = Notification.Name("appLog")
    static let appDidBecomeActive = Notification.Name("appDidBecomeActive")
    static let appWillBecomeActive = Notification.Name("appWillBecomeActive")
    static let appWillResignActive = Notification.Name("appWillResignActive")
}

#Preview("App - Small Screen") {
    ContentLayout()
        .setInitialTab(IconPlugin.label)
        .hideSidebar()
        .hideProjectActions()
        .hideTabPicker()
        .setInitialTab(IconPlugin.label)
        .inRootView()
        .frame(width: 800)
        .frame(height: 800)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideProjectActions()
        .hideTabPicker()
        .setInitialTab(IconPlugin.label)
        .hideSidebar()
        .setInitialTab(IconPlugin.label)
        .inRootView()
        .frame(width: 800)
        .frame(height: 1200)
}
